class ZoomClient
  include Zoom::API
end

ZOOM_CLIENT = ZoomClient.new
PASSWORD_GENERATION_SEED = Rails.env.test? ? 'test' : Base64.decode64(Rails.application.credentials.zoom[:password_generation_seed])

class ZoomLicense < ApplicationRecord
  def zoom_user
    @zoom_user ||= ZOOM_CLIENT.user(zoom_user_id)
  end

  def zoom_password(guide_id)
    digest = Digest::SHA1.base64digest("#{PASSWORD_GENERATION_SEED}#{guide_id}").first(8)
    # add a '-' in the string to make it easier to read
    g = 2 + guide_id % 6
    password = "#{digest[0...g]}-#{digest[g..-1]}"
    set_password(guide_id, password)
    password
  end

  private

  def set_password(guide_id, password)
    # FIXME: renable when we have a proper zoom license with non admin users
    # disabled for now because it fails with this error:
    # "An admin's password cannot be updated using this API."
    return

    # do not update the password if it is still the current password
    return unless last_guide_id != guide_id

    ZOOM_CLIENT.change_password(zoom_user_id, password)
    self.last_guide_id = guide_id
    save!
  ensure
    self.last_guide_id = nil
    save!
  end
end
