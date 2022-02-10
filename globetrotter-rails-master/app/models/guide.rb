# frozen_string_literal: true

class Guide < ApplicationRecord
  belongs_to :user, counter_cache: true
  has_many :tours # dependent deletion is managed through soft_delete
  has_many :events, through: :tours
  has_many :future_events, lambda {
                             where(cancelled_date: nil).where('tours.published = true').where('date > ?', Time.now.round).order(:date)
                           }, through: :tours, source: :events
  has_many :future_events_including_cancelled, lambda {
                                                 where('date > ?', Time.now.round).order(:date)
                                               }, through: :tours, source: :events
  has_many :comments, through: :tours

  has_one_attached :image

  validates :description, presence: true
  validates :short_description, presence: true
  validates :location, presence: true

  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }

  scope :for, ->(user) do
    return Guide if user&.admin?
    return Guide.published.or(Guide.where(user_id: user.id)) if user&.guide?
    
    Guide.published
  end

  def live_event
    fe = events.includes(tour: { image_attachment: :blob }).where('license_tsrange @> ?::timestamp',
                                                                  Time.now.round).first
    fe if fe&.can_be_started?
  end

  def soft_delete
    transaction do
      tours.each(&:soft_delete)
      self.published = false
      self.deleted_at = Time.now
      save!
    end
  end
end
