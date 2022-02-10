# frozen_string_literal: true

json.extract! event_registration, :id, :event_id, :user_id, :created_at, :updated_at
json.url event_registration_url(event_registration, format: :json)
