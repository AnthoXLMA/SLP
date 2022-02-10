# frozen_string_literal: true

require 'test_helper'

class User::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  setup do
  end

  ##############################
  #          NEW               #
  ##############################
  test 'it is possible to get a form to register' do
    get new_user_registration_path
    assert_response :success
  end

  #####################
  #      CREATE       #
  #####################
  test 'it is possible to register only when accepting terms and conditions' do
    assert_difference('User.count', 0) do
      post create_user_registration_path,
           params: { user: { email: 'toto@toto.com', password: '12345678', confirmation_password: '12345678',
                             language: 'en' } }
    end

    assert_select '.error.message',
                  Regexp.new(I18n.t('application.accept_terms_and_conditions.errors'))
  end

  def check_registration_with_language(language)
    assert_difference('User.count', 1) do
      post create_user_registration_path,
           params: { accept_terms_and_conditions: true, user: {
             email: 'toto@toto.com', password: '12345678', confirmation_password: '12345678',
             language: language
           } }
    end

    assert_redirected_to welcome_path(locale: language)
    get root_path
    assert_select '.message.notice',
                  Regexp.new(I18n.t('devise.registrations.signed_up_but_unconfirmed'))
  end

  test 'it is possible to register with an english account' do
    check_registration_with_language('en')
  end

  test 'it is possible to register with a french account' do
    check_registration_with_language('fr')
  end

  #####################
  #      EDIT         #
  #####################
  test 'it is required to be authenticated to get a form to edit an account' do
    get edit_user_registration_path
    assert_redirected_to new_user_session_path
  end

  test 'it is possible to get a form to edit an account' do
    sign_in users(:user_one)
    get edit_user_registration_path
    assert_response :success
  end

  test 'the form displays the current nationality, country, timezone' do
    user = users(:user_one)
    user.update(nationality: 'ES', country: 'MA', timezone: 'Africa/Lagos')
    sign_in users(:user_one)
    get edit_user_registration_path
    assert_response :success
    assert_select '#user_nationality > option[selected]', 'Spain'
    assert_select '#user_country option[selected]', 'Morocco'
    assert_select '#user_timezone > option[selected]', 'Angola - Lagos'
  end

  test 'the form allow blank values for nationality and country' do
    user = users(:user_one)
    user.update(nationality: nil, country: nil)
    sign_in users(:user_one)
    get edit_user_registration_path(locale: 'fr')
    assert_response :success
    assert_select '#user_nationality > option[selected]', 0
    assert_select '#user_nationality > option[value=""]', 'Veuillez sélectionner'
    assert_select '#user_country > option[selected]', 0
    assert_select '#user_country > option[value=""]', 'Veuillez sélectionner'
  end

  #####################
  #     UPDATE        #
  #####################
  test 'it is required to be authenticate to edit its account' do
    patch user_registration_path, params: {}
    assert_redirected_to new_user_session_path
  end

  test 'it is possible to edit nationality once connected' do
    user = users(:user_one)
    assert_nil user.nationality
    sign_in user
    patch user_registration_path, params: { user: { nationality: 'AF' } }
    user.reload
    assert_equal 'AF', user.nationality
  end

  #####################
  #      DELETE       #
  #####################
  test 'it is required to be signed_in to delete an account' do
    user = users(:guide_one)
    assert_difference('User.count', 0) do
      delete user_registration_path, params: { user_id: user.id }
      assert_redirected_to new_user_session_path
    end
  end
  test 'it is possible to delete an account' do
    user = users(:guide_one)
    sign_in user
    EventRegistration.create!(user: user, event: events(:event_one))

    # user is soft deleted
    assert_difference('User.count', 0) do
      assert_difference('User.where(deleted_at: nil).count', -1) do
        delete user_registration_path
        assert_redirected_to root_path
      end
    end
  end
end
