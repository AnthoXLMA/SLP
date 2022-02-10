module Zoom
  module WebClient
    # https://marketplace.zoom.us/docs/sdk/native-sdks/web/build/signature
    def generate_signature(meeting_number, role)
      ts = (Time.now.to_f * 1000).to_i - 30_000
      msg = "#{ZOOM_API_KEY}#{meeting_number}#{ts}#{role}"
      message = Base64.strict_encode64(msg)
      hash = OpenSSL::HMAC.digest('SHA256', ZOOM_API_SECRET, message)
      hash = Base64.strict_encode64(hash)
      tmp_string = [ZOOM_API_KEY, meeting_number, ts, role, hash].join('.')
      Base64.strict_encode64(tmp_string)
    end
  end
end
