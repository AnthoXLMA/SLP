# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(email: 'test@test.com', password: 'test_password')
  end

  test 'language must be set' do
    exception = assert_raises ActiveRecord::RecordInvalid do
      @user.save!
    end
    assert_match(/Language of site display can't be blank/, exception.message)
  end

  test 'language must be a supported language' do
    @user.language = 'de'
    exception = assert_raises ActiveRecord::RecordInvalid do
      @user.save!
    end
    assert_match(/Language of site display is not supported/, exception.message)
  end

  test 'if tour_language is not specified, the language of the user is used' do
    @user.language = 'fr'
    @user.save!
    assert_equal(['fr'], @user.tour_language)
  end

  test 'tour_language must be valid' do
    exception = assert_raises ActiveRecord::RecordInvalid do
      @user.language = 'en'
      @user.tour_language = 'en'
      @user.save!
    end
    assert_match(/must be an array/, exception.message)

    exception = assert_raises ActiveRecord::RecordInvalid do
      @user.language = 'en'
      @user.tour_language = ['de']
      @user.save!
    end
    assert_match(/unsupported language/, exception.message)
  end

  test 'soft_deletion mark dependent resources as soft_deleted' do
    user = users(:guide_one)
    u = User.includes(
      guide: {
        tours: {
          events: :event_registrations
        }
      },
      event_registrations: {

      }
    ).find(user.id)
    assert_difference 'User.where(deleted_at: nil).count', -1 do
      assert_difference 'User.count', 0 do
        assert_difference 'Guide.where(deleted_at: nil).count', -1 do
          u.soft_delete
        end
      end
    end
    u.reload
    assert(u.deleted_at > Time.now - 5.seconds)
    assert_match(/deleted\.\d+\.guide_one@test.com/, u.email)
  end
end
