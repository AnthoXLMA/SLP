# frozen_string_literal: true

require 'test_helper'

class TourTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test 'It displays all tours to the admin' do
    assert_equal(Tour.count, Tour.for(users(:admin)).count)
  end

  test 'It displays only published tours to unauthenticated users' do
    assert_equal(
      Tour.includes(:guide).references(:guide).where(guide: { published: true }).published.count,
      Tour.for(nil).count
    )

    g = guides(:guide_one)
    g.published = false
    g.save!
    assert_equal(
      Tour.includes(:guide).references(:guide).where(guide: { published: true }).published.count,
      Tour.for(nil).count
    )

  end

  test 'It displays only published tours and tours from the user if the user is a guide' do
    guides(:guide_one).tours.each do |t|
      t.published = false
      t.save!
    end

    assert_equal(Tour.published.count + Tour.where(guide: guides(:guide_one)).count,
     Tour.for(users(:guide_one)).count)
  end

  test 'A tour may have a next_event' do
    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW next_events')
    t = Tour.includes(:next_event).find_by(title: 'TestTour1')
    assert_equal(DateTime.now.utc.midnight + 5.days + 18.hours, t.next_event.date)
  end

  test 'A tour may have several future_events' do
    t = Tour.includes(:future_events).find_by(title: 'TestTour1')
    assert_equal(2, t.future_events.count)
  end

  test 'A tour has a duration' do
    assert_equal(30.minutes, tours(:tour_one).duration)
  end

  test 'By default, a tour is not published' do
    t = Tour.create!(
      guide: guides(:guide_one),
      country: countries(:country_one),
      title: 'test tour',
      subtitle: 'test tour subtitle',
      description: 'desc',
      short_description: 'short desc',
      duration: 'PT1H'
    )
    assert(!t.published)
  end

  test 'It is possible to list published tours' do
    assert(!Tour.published.pluck(:id).include?(tours(:unpublished_tour_one).id))
  end

  test 'Suggested tours tries to select only tours with events' do
    # TestTour1 and TestTour2 have a next event
    # TestTour3 doesn't have a next event
    # when requesting 3 tours: the 3 tours are listed
    expected = %w[TestTour1 TestTour2 TestTour3]
    assert_equal expected, Tour.suggested(nil, limit: 3).order(:title).pluck(:title)

    # when requesting only 2 tours, only the tours with events must be listed
    expected = %w[TestTour1 TestTour2]
    assert_equal expected, Tour.suggested(nil, limit: 2).order(:title).pluck(:title)

    # if we cancel all events for TestTour1, and limit to 1 tour, only the tour2 should be listed
    Event.includes(:event_registrations).where(tour: tours(:tour_one)).each do |e|
      e.cancel_and_save
    end
    NextEvent.refresh

    expected = %w[TestTour2]
    assert_equal expected, Tour.suggested(nil, limit: 1).order(:title).pluck(:title)
  end

  test 'Only published tours are suggested' do
    Tour.suggested(nil).each do |t|
      assert(t.published? && t.guide.published?)
    end
  end

  test 'Suggested tours does not include a tour that the user already subscribed to' do
    # user subscribed to TestTour1
    user = users(:user_one)
    user.tour_language = ['en']
    user.save!
    assert_equal %w[TestTour2 TestTour3], Tour.suggested(users(:user_one)).pluck(:title)
  end

  test 'Suggested tours must include a tour that the user already subscribed to if the event was cancelled' do
    user = users(:user_one)
    user.tour_language = ['en']
    user.save!

    Event.includes(:event_registrations).joins(:event_registrations).where(
      'event_registrations.user_id' => users(:user_one).id, 'events.tour_id' => tours(:tour_one).id
    ).each do |e|
      e.cancel_and_save
    end
    NextEvent.refresh
    assert_equal %w[TestTour1 TestTour2 TestTour3], Tour.suggested(users(:user_one)).order(:title).pluck(:title)
  end

  test 'Suggested tours does not include an unpublished tour' do
    t = tours(:tour_two)
    t.published = false
    t.save!

    assert_equal %w[TestTour1 TestTour3], Tour.suggested(nil).pluck(:title)
  end

  test 'Suggested tours only include tours that match the selected language for the user' do
    t = tours(:tour_two)
    t.language = 'fr'
    t.save!

    user = users(:user_one)
    user.tour_language = ['fr']
    user.save!
    assert Tour.suggested(user).map(&:title).include?(t.title)

    user.tour_language = ['en']
    user.save!
    assert !Tour.suggested(user).map(&:title).include?(t.title)
  end
end
