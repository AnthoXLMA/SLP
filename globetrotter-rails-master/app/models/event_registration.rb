# frozen_string_literal: true

class EventRegistration < ApplicationRecord
  belongs_to :event
  belongs_to :user

  # event_registration can be deleted when a user cancels a registration (or delete its account)
  # in case it is due to the account been cancelled, we have to delete dependent comments
  has_one :comment, dependent: :delete

  validates :user, uniqueness: {
    scope: :event,
    message: 'already registered to this event.'
  }
  validate :visited_date_during_live_range

  def tour
    event.tour
  end

  def visited?
    !visited_date.nil?
  end

  def send_cancellation(method = :deliver_now, mailer = ApplicationMailer)
    mailer.with({ event_registration_id: id })
          .event_cancellation
          .send(method)
  end

  private

  def visited_date_during_live_range
    if visited_date
      e = Event.includes(:tour).find(event_id)
      errors.add(:visited_date, 'must happen when event is live') unless e.live_range.cover?(visited_date)
    end
  end
end
