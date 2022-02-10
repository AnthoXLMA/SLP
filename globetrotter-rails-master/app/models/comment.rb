# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :event_registration
  has_one :event, through: :event_registration
  has_one :tour, through: :event
end
