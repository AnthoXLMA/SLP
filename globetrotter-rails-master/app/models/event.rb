# frozen_string_literal: true

class Event < ApplicationRecord
  BOOK_ZOOM_LICENSE_BEFORE_EVENT_IN_MINUTES = 15
  BOOK_ZOOM_LICENSE_AFTER_EVENT_IN_MINUTES = 30
  LIVE_BEFORE_EVENT_IN_MINUTES = 10

  belongs_to :tour
  belongs_to :zoom_license
  has_many :event_registrations # dependent deletion is managed through soft_delete

  validates :date, presence: true
  validates :guide_id, presence: true
  validate :guide_not_already_booked, :license_not_already_booked, :date_in_the_future, :tour_is_published

  scope :for, ->(user) do
    return Event if user&.admin?

    published_events = Event.joins(:tour => :guide).where(tours: { published: true }).where(guides: {published: true})
    return published_events.or(Event.where(guides: { user_id: user.id })) if user&.guide?

    published_events
  end

  scope :with_date_in_range, lambda { |range|
    if range.begin && range.end
      where('date between ? and ?', range.begin, range.end)
    elsif range.begin
      where('date >= ?', range.begin)
    elsif range.end
      where('date <= ?', range.end)
    end
  }

  scope :with_hour_of_day_in_range, lambda { |range|
    timezone = Time.zone.tzinfo.name
    if range.begin && range.end
      where("extract(hour from events.date at time zone 'utc' at time zone ?) between ? and ?", timezone, range.begin, range.end)
    elsif range.begin
      where("extract(hour from events.date at time zone 'utc' at time zone ?) >= ?", timezone, range.begin)
    elsif range.end
      where("extract(hour from events.date at time zone 'utc' at time zone ?)*60 + extract(minute from events.date at time zone 'utc' at time zone ?) <= ? * 60", timezone, timezone, range.end)
    end
  }

  # use negative form to avoid the where clause when all days are selected
  scope :with_day_of_week_not_in, lambda { |ids|
    timezone = Time.zone.tzinfo.name
    where("extract(dow from events.date at time zone 'utc' at time zone ?) not in (?)", timezone, ids) if ids.any?
  }

  def soft_delete
    transaction do
      self.deleted_at = Time.now
      cancel_and_save
    end
  end

  def can_be_started?
    license_tsrange&.cover?(Time.now)
  end

  def live?
    live_range.cover?(Time.now.round)
  end

  def past?
    live_range.end < Time.now.round
  end

  def future?
    live_range.begin > Time.now.round
  end

  def live_start_date
    live_range.begin
  end

  def cancel_and_save(mailer = ApplicationMailer)
    self.cancelled_date = Time.now
    self.zoom_license_id = nil
    self.license_tsrange = nil
    save!(validate: false)

    event_registrations.each { |er| er.send_cancellation(:deliver_later, mailer) }
    send_cancellation_to_guide(:deliver_later, mailer)
  end

  def send_cancellation_to_guide(method = :deliver_later, mailer = ApplicationMailer)
    mailer.with({ event_id: id })
          .event_unscheduled
          .send(method)
  end

  def cancelled?
    !cancelled_date.nil?
  end

  before_validation do
    if date
      self.license_tsrange ||= default_license_range
      self.guide_id ||= tour.guide_id
      self.zoom_license_id ||= preferred_license_id
    end
  end

  def free_license_ids
    return [] unless date

    dlr = license_tsrange || default_license_range
    ZoomLicense
      .where(
        'not exists (:events)',
        events:
          Event
            .where(cancelled_date: nil)
            .where('zoom_licenses.id = events.zoom_license_id')
            .where('events.license_tsrange && tsrange(?, ?)', dlr.begin, dlr.end)
      ).pluck(:id)
  end

  def preferred_license_id
    preferred_license_id = tour.guide.zoom_license_id
    possible_license_ids = free_license_ids
    return preferred_license_id if possible_license_ids.include?(preferred_license_id)

    tour.guide.zoom_license_id = possible_license_ids.first
  end

  def preferred_license
    pl_id = preferred_license_id
    pl_id && ZoomLicense.find(preferred_license_id)
  end

  def live_range
    (date - LIVE_BEFORE_EVENT_IN_MINUTES.minutes)..(date + tour.duration)
  end

  private

  def default_license_range
    (date - BOOK_ZOOM_LICENSE_BEFORE_EVENT_IN_MINUTES.minutes)..(date + tour.duration + BOOK_ZOOM_LICENSE_AFTER_EVENT_IN_MINUTES.minutes)
  end

  def guide_not_already_booked
    return unless will_save_change_to_attribute? :license_tsrange

    if license_tsrange &&
       Event.where(cancelled_date: nil, guide_id: guide_id)
            .where('license_tsrange && tsrange(?, ?)', license_tsrange.begin, license_tsrange.end)
            .first
      errors.add(:date, 'is already booked for this guide')
    end
  end

  def license_not_already_booked
    return if zoom_license_id && !will_save_change_to_attribute?(:zoom_license_id)

    unless zoom_license_id
      errors.add(:zoom_license, 'can not be booked at the specified date')
      return
    end

    if Event
       .where(cancelled_date: nil, zoom_license_id: zoom_license_id)
       .where('license_tsrange && tsrange(?, ?)', license_tsrange.begin, license_tsrange.end)
       .first
      errors.add(:zoom_license, 'is already booked for this date')
    end
  end

  def date_in_the_future
    errors.add(:date, 'must be in the future') if date && date < Time.now
  end

  def tour_is_published
    errors.add(:tour, 'must be published') unless tour&.published
  end
end
