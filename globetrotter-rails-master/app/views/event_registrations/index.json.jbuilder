# frozen_string_literal: true

json.array! @event_registrations, partial: 'event_registrations/event_registration', as: :event_registration
