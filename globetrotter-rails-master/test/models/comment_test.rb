# frozen_string_literal: true

require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  test 'it is not possible to create a comment without event_registration' do
    exception = assert_raises ActiveRecord::RecordInvalid do
      c = Comment.new
      c.save!
    end

    assert_equal 'Validation failed: Event registration must exist', exception.message
  end

  test 'it is not possible to create two comments with the same event_registration' do
    exception = assert_raises ActiveRecord::RecordNotUnique do
      Comment.new(event_registration: event_registrations(:event_registration_one)).save
    end

    assert_match(/duplicate key value violates unique constraint/, exception.message)
  end
end
