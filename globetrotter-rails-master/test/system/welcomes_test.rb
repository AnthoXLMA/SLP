# frozen_string_literal: true

require 'application_system_test_case'

class WelcomesTest < ApplicationSystemTestCase
  driven_by :selenium, using: :headless_chrome
  test 'visiting the index' do
    visit '/'

    assert_selector 'h1', text: 'theGlobetrotters.live'
    assert_selector 'a.signin', text: 'Sign In'
  end
end
