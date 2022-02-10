require 'test_helper'

class User::SessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  test 'it is not possible to sign in when the user has been deleted' do
    user = User.includes(:guide, event_registrations: :comment).find(users(:user_one).id)
    user.soft_delete

    sign_in user
    get edit_user_registration_path

    assert_redirected_to new_user_session_path
  end

  def check_signin_with_language(language)
    user = User.includes(:guide, event_registrations: :comment).find(users(:user_one).id)
    user.language = language
    user.save!

    sign_in user
    post new_user_session_path, params: {
      user: {
        email: user.email,
        password: user.password
      }
    }
    assert_redirected_to welcome_path(language)
  end

  test 'the language preference of the user is taken into account' do
    check_signin_with_language('en')
    check_signin_with_language('fr')
  end
end
