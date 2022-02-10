# frozen_string_literal: true

class User < ApplicationRecord
  LANGUAGE_NAMES = {
    'fr' => 'Français',
    'en' => 'English'
  }

  has_many :event_registrations # dependent deletion is managed through soft_delete
  has_many :events, through: :event_registrations
  has_many :future_events_including_cancelled, lambda {
                                                 where('date > ?', Time.now.round)
                                               }, through: :event_registrations, source: :event

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  has_one :guide # dependent deletion is managed through soft_delete

  validates :language, presence: true, inclusion: { in: LANGUAGE_NAMES.keys, message: 'is not supported' }
  validate :validate_tour_language

  before_validation do
    self.tour_language = [language] if tour_language.nil? || tour_language.empty?
  end

  def man?
    sex == 'M'
  end

  def guide?
    guides_count == 1
  end

  def birthdate_unix
    birthdate.to_time.to_i + birthdate.to_time.utc_offset.to_i
  end

  def tour_admin?(tour)
    admin? || (tour.guide&.user_id == id)
  end

  def language_name
    LANGUAGE_NAMES[language]
  end

  def name
    firstname || lastname || email
  end

  # live if
  # event.date - LIVE_BEFORE_EVENT_IN_MINUTES.minutes <= Time.now < event.date + tour.duration
  # i.e. event.date <= Time.now + LIVE_BEFORE_EVENT_IN_MINUTES.minutes
  #      && Time.now < event.date + tour.duration
  def live_registration
    live_registrations = EventRegistration
                         .includes(event: { tour: { image_attachment: :blob } })
                         .references(:tours)
                         .where(user_id: id)
                         .where(
                           'events.date <= ? and ? < events.date + tours.duration',
                           Time.now.round + Event::LIVE_BEFORE_EVENT_IN_MINUTES.minutes,
                           Time.now.round
                         )
                         .order('events.date' => :asc)
    live_registrations.first
  end

  def soft_delete
    transaction do
      guide&.soft_delete
      # do not soft delete here: the registrations of the user can be deleted
      event_registrations.destroy_all
      self.deleted_at = Time.now
      self.email = "deleted.#{deleted_at.to_i}.#{email}" # avoid issues with uniq constraint
      @bypass_confirmation_postpone = true # avoid email changed to be notified to the user
      save!
    end
  end

  def active_for_authentication?
    deleted_at.nil?
  end

  private

  def validate_tour_language
    return errors.add(:tour_language, 'must be an array') unless tour_language.is_a? Array
    return errors.add(:tour_language, 'must not be empty') if tour_language.empty?

    errors.add(:tour_language, 'contains an unsupported language') unless tour_language.all? do |v|
                                                                            LANGUAGE_NAMES.has_key?(v)
                                                                          end
  end
end
