require 'test_helper'

class TestApplicationHelper
  include ApplicationHelper
end

class ApplicationHelperTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'cgu_url' do
    ta = TestApplicationHelper.new
    I18n.with_locale(:fr) do
      assert_equal ApplicationHelper::CGU_FR_URL, ta.cgu_url
    end
    I18n.with_locale(:en) do
      assert_equal ApplicationHelper::CGU_EN_URL, ta.cgu_url
    end
 end
end  