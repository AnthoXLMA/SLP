# frozen_string_literal: true

require 'test_helper'

module Devise
  class MailerTest < ActionMailer::TestCase
    # Add more helper methods to be used by all tests here...
    TEST_CONFIG = [{
      mailer_method: 'confirmation_instructions',
      user: ->(_) { users(:user_one) },
      params: ->(_) { [users(:user_one), 'token'] },
      email_title: {
        en: 'Confirmation instructions',
        fr: 'Instructions de confirmation'
      }
    }, {
      mailer_method: 'reset_password_instructions',
      user: ->(_) { users(:user_one) },
      params: ->(_) { [users(:user_one), 'token'] },
      email_title: {
        en: 'Reset password instructions',
        fr: 'Instructions pour changer le mot de passe'
      }
    }, {
      mailer_method: 'unlock_instructions',
      user: ->(_) { users(:user_one) },
      params: ->(_) { [users(:user_one), 'token'] },
      email_title: {
        en: 'Unlock instructions',
        fr: 'Instructions pour déverrouiller le compte'
      }
    }, {
      mailer_method: 'email_changed',
      user: ->(_) { users(:user_one) },
      params: ->(_) { [users(:user_one)] },
      email_title: {
        en: 'Email Changed',
        fr: 'Courriel modifié'
      }
    }, {
      mailer_method: 'password_change',
      user: ->(_) { users(:user_one) },
      params: ->(_) { [users(:user_one)] },
      email_title: {
        en: 'Password Changed',
        fr: 'Mot de passe modifié'
      }
    }].freeze
    TEST_CONFIG.each { |c| install_test_mail(c.merge(locale: 'en')) }
    TEST_CONFIG.each { |c| install_test_mail(c.merge(locale: 'fr')) }
  end
end
