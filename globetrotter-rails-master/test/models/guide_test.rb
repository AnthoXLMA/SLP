# frozen_string_literal: true

require 'test_helper'

class GuideTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test 'it displays all guides to the admin' do
    assert_equal(Guide.count, Guide.for(users(:admin)).count)
  end

  test 'it displays only published guide to unauthenticated users' do
    assert_equal(Guide.published.count, Guide.for(nil).count)
  end

  test 'it displays only published guide and the guide related to the user if the user is a guide' do
    g = guides(:guide_one)
    g.published = false
    g.save!
    assert_equal(Guide.published.count + 1, Guide.for(g.user).count)
  end
end
