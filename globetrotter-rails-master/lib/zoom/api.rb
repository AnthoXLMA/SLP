# frozen_string_literal: true

module Zoom
  module API
    %i[get post put delete].each do |m|
      define_method(m) do |route, params|
        with_connection do |conn|
          r = conn.send(m, "/v2#{route}", params ? JSON.generate(params) : nil)
          raise "#{r.status}: #{r.body}" unless r.success?

          JSON.parse(r.body) if r.body && !r.body.empty?
        end
      end
    end

    def metrics_meetings_participants_qos(meeting_id, params = nil)
      get("/metrics/meetings/#{meeting_id}/participants/qos", params)
    end

    def metrics_meetings_participants_statisfaction(meeting_id, params = nil)
      get("/metrics/meetings/#{meeting_id}/participants/satisfaction", params)
    end

    DEFAULT_ZOOM_CREATE_PARAMS = {
      topic: 'Globetrotter',
      type: 2, # scheduled meeting
      duration: 60,
      timezone: 'UTC',
      settings: {
        host_video: true,
        participant_video: false,
        join_before_host: true,
        mute_upon_entry: true,
        audio: 'voip'
      }
    }.freeze
    def create_meeting(user_id, start_time, params = {})
      p = DEFAULT_ZOOM_CREATE_PARAMS.merge(params)
      p[:start_time] = start_time.iso8601
      Rails.logger.debug "about to execute /users/#{user_id}/meetings : #{p}"
      post("/users/#{user_id}/meetings", p)
    end

    def delete_meeting(meeting_id, params = nil)
      delete("/meetings/#{meeting_id}", params)
    end

    def users(params = nil)
      get('/users', params)
    end

    def user(user_id, params = nil)
      get("/users/#{user_id}", params)
    end

    def change_password(user_id, new_password)
      put("/users/#{user_id}/password", password: new_password)
    end

    private

    def with_connection(&block)
      $zoom_connection_pool ||= Zoom::ConnectionPool.new
      $zoom_connection_pool.with_connection(&block)
    end
  end
end
