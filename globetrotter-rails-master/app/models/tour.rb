# frozen_string_literal: true

class Tour < ApplicationRecord
  DEFAULT_SUGGESTED_COUNT = 4
  POSSIBLE_DURATIONS = %w[PT30M PT45M PT1H PT1H15M PT1H30M].freeze
  LANGUAGE = {
    en: 'English',
    fr: 'Français'
  }

  attribute :duration, :interval
  has_one_attached :image
  has_one_attached :thumbnail
  belongs_to :guide
  has_many :events # dependent deletion is managed through soft_deletey
  has_many :future_events, lambda {
                             where(cancelled_date: nil).where('date > ?', Time.now.round).order(:date)
                           }, class_name: 'Event', inverse_of: :tour
  has_many :future_events_including_cancelled, lambda {
                                                 where('date > ?', Time.now.round).order(:date)
                                               }, class_name: 'Event', inverse_of: :tour
  has_one :next_event
  has_many :event_registrations, through: :events
  has_many :comments, -> { where.not(comment: nil) }, through: :event_registrations
  belongs_to :country

  validates :title, presence: true
  validates :subtitle, presence: true
  validates :description, presence: true
  validates :short_description, presence: true
  validates :duration, presence: true

  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }

  scope :for, ->(user) do
    tour_with_guide = Tour.joins(:guide)
    return tour_with_guide if user&.admin?
    return tour_with_guide.published.where(guides: {published: true}).or(Tour.where(guides: { user_id: user.id })) if user&.guide?

    tour_with_guide.published.where(guides: {published: true})
  end

  def self.suggested(current_user, limit: DEFAULT_SUGGESTED_COUNT)
    t = Tour.for(current_user)
            .includes(:next_event)
            .references(:next_events)
            .order('date asc nulls last')
            .limit(limit)
    t = yield(t) if block_given?
    if current_user
      t = t.where(
        'not exists (:visited)',
        visited: User
          .joins(event_registrations: :event)
          .where(id: current_user.id)
          .where('events.cancelled_date is null')
          .where('events.tour_id = tours.id')
      )
      t = t.where(language: current_user.tour_language)
    end
    ids = t.pluck(:id)
    Tour.includes(guide: [:user, { image_attachment: :blob }])
        .includes(thumbnail_attachment: :blob)
        .includes(:next_event)
        .where(id: ids)
  end

  def rating
    comments.average(:rating)
  end

  def comments_count
    comments.count
  end

  def registrations_for_user(user)
    @registrations_for_user ||= {}
    @registrations_for_user[user] ||= event_registrations.where(user: user).includes(:comment)
  end

  def past_registrations_for_user(user)
    registrations_for_user(user).where('events.date < ?', Time.now.round).order('events.date' => :desc)
  end

  def soft_delete
    transaction do
      events.each(&:soft_delete)
      self.published = false
      self.deleted_at = Time.now
      save!
    end
  end
end
