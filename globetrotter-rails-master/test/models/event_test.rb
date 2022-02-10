# frozen_string_literal: true

require 'test_helper'

class EventTest < ActiveSupport::TestCase
  setup do
    Comment.delete_all
    EventRegistration.delete_all
    Event.delete_all
    @winter_event = Event.create!(tour: tours(:tour_one), date: DateTime.new(2050, 1, 30, 15, 15))
    @summer_event = Event.create!(tour: tours(:tour_one), date: DateTime.new(2050, 8, 30, 15, 15))
  end
  test 'only events for published tours and published guides are shown to unauthenticated users' do
    assert_equal(Event.for(nil).count, Event.joins(:tour => :guide).where("tours.published and guides.published").count)
  end
  test 'all events are shown to admin' do
    assert_equal(Event.for(users(:admin)).count, Event.count)
  end
  test 'all events + events for the guide are shown to a guide' do
    g = guides(:guide_one)
    g.published = false
    g.save!
    assert_equal(Event.for(users(:guide_one)).count, Event.joins(:tour => :guide).where("tours.published and guides.published").count + g.events.count)
  end
  test 'an event can be linked to a license' do
    Event.create!(
      date: Time.now + 10.minutes,
      tour: tours(:tour_one),
      zoom_license: zoom_licenses(:one)
    )
  end
  test 'the same license can not be used by two events at the same time' do
    Event.create!(
      date: Time.now + 1.hour,
      tour_id: tours(:tour_one).id,
      zoom_license_id: zoom_licenses(:one).id
    )
    exception = assert_raises ActiveRecord::RecordInvalid do
      Event.create!(
        date: Time.now + 1.hour,
        tour_id: tours(:tour_two).id,
        zoom_license_id: zoom_licenses(:one).id
      )
    end
    assert_match(/Zoom license is already booked for this date/, exception.message)
  end
  test 'if the preferred license of the guide is available, this license is the preferred license for an event' do
    tour = tours(:tour_one)
    guide = tour.guide
    guide.zoom_license_id = zoom_licenses(:one).id
    event = Event.new(
      date: Time.now,
      tour_id: tours(:tour_one).id
    )
    event.instance_variable_set(:@strict_loading, false)
    event.tour.instance_variable_set(:@strict_loading, false)
    assert_equal guide.zoom_license_id, event.preferred_license_id
  end
  test 'if the preferred license of the guide is not available, the preferred license for an event must be another license' do
    tour = tours(:tour_one)
    guide = tour.guide
    guide.zoom_license_id = zoom_licenses(:one).id
    Event.create!(
      date: Time.now + 1.hour,
      tour_id: tours(:tour_one).id,
      zoom_license_id: zoom_licenses(:one).id
    )
    event = Event.new(
      date: Time.now + 1.hour,
      tour_id: tours(:tour_one).id
    )
    event.instance_variable_set(:@strict_loading, false)
    event.tour.instance_variable_set(:@strict_loading, false)
    assert_not_equal guide.zoom_license_id, event.preferred_license_id
  end
  test 'if no license is available, there should be no preferred license' do
    Event.create!(
      date: Time.now + 1.hour,
      tour_id: tours(:tour_one).id,
      zoom_license_id: zoom_licenses(:one).id
    )
    Event.create!(
      date: Time.now + 1.hour,
      tour_id: tours(:tour_two).id,
      zoom_license_id: zoom_licenses(:two).id
    )
    event = Event.new(
      date: Time.now + 1.hour,
      tour_id: tours(:tour_one).id
    )
    event.instance_variable_set(:@strict_loading, false)
    event.tour.instance_variable_set(:@strict_loading, false)
    assert_nil event.preferred_license_id
  end
  test 'it raises an error if the guide is not free' do
    Event.create!(
      date: Time.now + 1.hour,
      tour_id: tours(:tour_one).id,
      zoom_license_id: zoom_licenses(:one).id
    )
    exception = assert_raise ActiveRecord::RecordInvalid do
      Event.create!(
        date: Time.now + 1.hour,
        tour_id: tours(:tour_one).id,
        zoom_license_id: zoom_licenses(:two).id
      )
    end
    assert_match(/Date is already booked for this guide/, exception.message)
  end

  test 'it raises an error if the tour is not published' do
    Event.create!(
      date: Time.now + 1.hour,
      tour_id: tours(:tour_one).id,
      zoom_license_id: zoom_licenses(:one).id
    )
    exception = assert_raise ActiveRecord::RecordInvalid do
      Event.create!(
        date: Time.now + 1.hour,
        tour_id: tours(:unpublished_tour_one).id,
        zoom_license_id: zoom_licenses(:two).id
      )
    end
    assert_match(/Tour must be published/, exception.message)
  end
  test 'it raises an error if the event has no date or no guide' do
    exception = assert_raise ActiveRecord::RecordInvalid do
      event = Event.new
      event.instance_variable_set(:@strict_loading, false)
      event&.tour&.instance_variable_set(:@strict_loading, false)
      event.save!
    end
    assert_match(/Date can't be blank/, exception.message)
    assert_match(/Guide can't be blank/, exception.message)
  end
  test 'it can be filtered by hour of day' do
    # there are two events at 15:15 utc
    all_events_hours = Event.pluck(:date).map(&:hour).sort
    assert_equal [15, 15], all_events_hours

    selected = Event.with_hour_of_day_in_range(15..18).pluck(:date).map(&:hour).sort
    assert_equal [15, 15], selected

    selected = Event.with_hour_of_day_in_range(16..).pluck(:date).map(&:hour).sort
    assert_equal [], selected

    selected = Event.with_hour_of_day_in_range(..15).pluck(:date).map(&:hour).sort
    assert_equal [], selected # events are at 15:15

    selected = Event.with_hour_of_day_in_range(..16).pluck(:date).map(&:hour).sort
    assert_equal [15, 15], selected
  end

  test 'it can be filtered by hour of day using the appropriate timezone' do
    Time.use_zone('Europe/Paris') do
      selected = Event.with_hour_of_day_in_range(17..18).pluck(:date).map(&:hour).sort
      # event planned in winter at 15:15 utc should not be listed:
      # in winter, Europe/Paris is utc+1, and thus event is at 16:15 paris time
      # event planned in summer at 15 utc should be listed:
      # in summer, Europe/Paris is utc+2, and this event is at 17:15 paris time
      assert_equal [17], selected

      selected = Event.with_hour_of_day_in_range(16..).pluck(:date).map(&:hour).sort
      assert_equal [16, 17], selected

      selected = Event.with_hour_of_day_in_range(..16).pluck(:date).map(&:hour).sort
      assert_equal [], selected # event is at 16:15 so after 16:00

      selected = Event.with_hour_of_day_in_range(..17).pluck(:date).map(&:hour).sort
      assert_equal [16], selected
    end
  end

  test 'it can be filtered by day of week' do
    selected = Event.with_day_of_week_not_in([]).map { |e| e.date.strftime('%A') }.sort
    assert_equal %w[Sunday Tuesday], selected

    selected = Event.with_day_of_week_not_in([0, 2]).map { |e| e.date.strftime('%A') }.sort
    assert_equal [], selected
  end

  test 'it can be filtered by date' do
    assert_equal 2, Event.with_date_in_range(@winter_event.date..@summer_event.date).count

    Time.use_zone('Europe/Paris') do
      d = Time.local(2050, 1, 30, 16, 16)
      selected = Event.with_date_in_range(d..).count
      # event planned in winter at 15:15 utc should not be listed:
      # in winter, Europe/Paris is utc+1, and thus event is at 16:15 paris time
      # event planned in summer at 15 utc should be listed:
      # in summer, Europe/Paris is utc+2, and this event is at 17:15 paris time
      assert_equal 1, selected
    end
  end

  test 'a valid event can be saved twice' do
    e = Event.new(
      date: Time.now + 10.minutes,
      tour: tours(:tour_one),
      zoom_license: zoom_licenses(:one)
    )
    e.save!
    e.save!
  end

  test 'a valid event can be cancelled' do
    e = Event.new(
      date: Time.now + 10.minutes,
      tour: tours(:tour_one)
    )
    e.save!

    e.reload
    e.instance_variable_set(:@strict_loading, false)
    e.tour.instance_variable_set(:@strict_loading, false)
    e.cancel_and_save
    assert_nil(e.zoom_license_id)
    assert_nil(e.license_tsrange)

    # after cancellation, the same date can be booked again for the guide
    e = Event.new(
      date: Time.now + 10.minutes,
      tour: tours(:tour_one)
    )
    e.save!
  end
end
