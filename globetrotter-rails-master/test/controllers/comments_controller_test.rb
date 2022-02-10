# frozen_string_literal: true

require 'test_helper'

class CommentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  setup do
    @comment = comments(:one)
    @event_registration =  event_registrations(:event_registration_event_one_user_two)
    @future_event_registration = event_registrations(:event_registration_three)
    @valid_comment_params = {
      event_registration_id: @event_registration.id,
      rating: 3,
      comment: 'yehee!!'
    }
  end

  def last_comment
    c = Comment.last
    c.instance_variable_set(:@strict_loading, false)
    c
  end

  #####################
  #      CREATE       #
  #####################
  test 'it is needed to be authenticated to create a comment' do
    post comments_url, params: { comment: {} }

    assert_redirected_to new_user_session_url
  end

  test 'it is possible to create a comment' do
    user = users(:user_two)
    sign_in user

    assert_difference('Comment.count') do
      post comments_url, params: { comment: @valid_comment_params }
    end

    assert_redirected_to tour_url(last_comment.tour)
  end

  test 'it is not possible to create 2 comments for the same registration' do
    user = users(:user_two)
    sign_in user

    assert_difference('Comment.count', 1) do
      post comments_url, params: { comment: @valid_comment_params }
      assert_redirected_to tour_url(last_comment.tour)

      post comments_url, params: { comment: @valid_comment_params }
      assert_response 400
    end
  end

  test 'it is not possible to create a comment for an event_registration which is not linked to the user' do
    user = users(:user_one)
    sign_in user

    assert_difference('Comment.count', 0) do
      post comments_url, params: { comment: @valid_comment_params }
      assert_response 403
    end
  end

  test 'it is not possible to create a comment for an event that has not been visited' do
    user = users(:user_one)
    sign_in user

    assert_difference('Comment.count', 0) do
      post comments_url,
           params: { comment: @valid_comment_params.merge(event_registration_id: @future_event_registration.id) }

      assert_response 403
    end
  end

  #####################
  #      UPDATE       #
  #####################
  test 'it is needed to be authenticated to update a comment' do
    patch comment_url(@comment), params: { comment: {} }

    assert_redirected_to new_user_session_url
  end

  test 'it is possible to update a comment' do
    user = users(:user_one)
    sign_in user

    patch comment_url(@comment), params: { comment: { rating: 3, comment: 'updated!' } }
    @comment.reload
    assert_equal 'updated!', @comment.comment
    assert_equal 3, @comment.rating
    assert_redirected_to tour_url(@comment.tour)
  end

  test "it is not possible to update someone else's comment" do
    user = users(:user_two)
    sign_in user

    patch comment_url(@comment), params: { comment: { rating: 1, comment: 'updated!' } }
    @comment.reload
    assert_equal 1, @comment.rating
    assert_equal 'MyText', @comment.comment
    assert_response 403
  end

  #####################
  #      DESTROY      #
  #####################
  test 'it is required to be authenticated to destroy a comment' do
    delete comment_url(@comment)

    assert_redirected_to new_user_session_url
  end

  test 'it is possible to destroy a comment' do
    user = users(:user_one)
    sign_in user

    assert_difference('Comment.count', -1) do
      delete comment_url(@comment)
    end

    assert_redirected_to tour_url(@comment.tour)
  end

  test "it is not possible to destroy someone else's comment" do
    user = users(:user_two)
    sign_in user

    assert_difference('Comment.count', 0) do
      delete comment_url(@comment)
    end

    assert_response 403
  end
end
