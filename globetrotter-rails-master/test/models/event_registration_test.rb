# frozen_string_literal: true

require 'test_helper'

class EventRegistrationTest < ActiveSupport::TestCase
  test 'it is not possible to register twice to the same event' do
    # user one is already registered to event one:
    assert_equal 1, EventRegistration.where(user: users(:user_one), event: events(:event_one)).count

    # it is not possible to register a 2nd time:
    exception = assert_raise ActiveRecord::RecordInvalid do
      EventRegistration.create!(user: users(:user_one), event: events(:event_one))
    end
    assert_match(/User already registered to this event/, exception.message)
  end
end
