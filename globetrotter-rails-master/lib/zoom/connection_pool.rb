# frozen_string_literal: true

module Zoom
  ZOOM_API_KEY = Rails.application.credentials.zoom[:api_key]
  ZOOM_API_SECRET = Rails.application.credentials.zoom[:api_secret]
  JWT_ALGO = 'HS256'
  CONNECTION_POOL_SIZE = ENV.fetch('RAILS_MAX_THREADS', 5)
  ZOOM_BASE_URL = 'https://api.zoom.us/v2'
  ZOOM_HEADERS = { 'Content-Type' => 'application/json' }.freeze

  ConnectionInfo = Struct.new(:conn, :jwt_expiry)

  class ConnectionPool
    def initialize(pool_size: CONNECTION_POOL_SIZE)
      @connections = Queue.new
      pool_size.times do
        conn = Faraday.new(url: ZOOM_BASE_URL, headers: ZOOM_HEADERS)
        @connections.push ConnectionInfo.new(conn)
      end
    end

    def renew_token(conn_info)
      now = Time.now.round
      if conn_info.jwt_expiry.nil? || (conn_info.jwt_expiry - 2.minutes) < now # will be expired in less than two minutes
        new_expiry = now + 10.minutes
        Rails.logger.debug "Renewing token. Current expiry=#{conn_info.jwt_expiry&.iso8601}, new expiry=#{new_expiry}"
        conn_info.jwt_expiry = new_expiry
        conn_info.conn.headers.update({ 'Authorization' => "bearer #{jwt(new_expiry)}" })
      end
    end

    def jwt(exp)
      payload = {
        iss: ZOOM_API_KEY,
        exp: exp.to_i
      }
      JWT.encode(payload, ZOOM_API_SECRET, JWT_ALGO, typ: 'JWT')
    end

    def with_connection
      conn_info = @connections.pop
      begin
        renew_token(conn_info)
        yield conn_info.conn
      ensure
        @connections.push conn_info
      end
    end
  end
end
