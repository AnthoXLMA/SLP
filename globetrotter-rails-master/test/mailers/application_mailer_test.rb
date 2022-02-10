# frozen_string_literal: true

require 'test_helper'

class ApplicationMailerTest < ActionMailer::TestCase
  TEST_CONFIG = [{
    mailer_method: 'event_registration',
    user: ->(_) { users(:user_one) },
    params: ->(_) { { user_id: users(:user_one).id, event_id: events(:event_one).id } },
    email_title: {
      en: 'Your flight is now confirmed!',
      fr: 'Votre vol est confirmé!'
    },
    ignore_fixture: true,
    using_with: true
  }, {
    mailer_method: 'event_cancellation',
    user: ->(_) { users(:user_one) },
    params: ->(_) { { event_registration_id: event_registrations(:event_registration_one).id } },
    email_title: {
      en: 'Oh no! Your tour has been cancelled.',
      fr: 'Oh non! Votre tour a été annulé.'
    },
    ignore_fixture: true,
    using_with: true
  }, {
    mailer_method: 'event_about_to_start',
    user: ->(_) { users(:user_one) },
    params: ->(_) { { user_id: users(:user_one).id, event_id: events(:event_one).id } },
    email_title: {
      en: 'Final call for boarding!',
      fr: "Dernier appel avant l'embarquement!"
    },
    ignore_fixture: true,
    using_with: true
  }, {
    mailer_method: 'event_scheduled',
    user: ->(_) { users(:guide_one) },
    params: ->(_) { { event_id: events(:event_one).id } },
    email_title: {
      en: 'Your event is scheduled.',
      fr: 'Votre évènement est planifié.'
    },
    ignore_fixture: true,
    using_with: true
  }, {
    mailer_method: 'event_unscheduled',
    user: ->(_) { users(:guide_one) },
    params: ->(_) { { event_id: events(:event_one).id } },
    email_title: {
      en: 'Your event is not scheduled anymore.',
      fr: 'Votre évènement est déprogrammé.'
    },
    ignore_fixture: true,
    using_with: true
  }].freeze
  TEST_CONFIG.each { |c| install_test_mail(c.merge(locale: 'en')) }
  TEST_CONFIG.each { |c| install_test_mail(c.merge(locale: 'fr')) }

  test 'event_about_to_start does not send an email if the event is cancelled' do
    event = Event.includes(:event_registrations).find(events(:event_one).id)
    event.cancel_and_save

    params = { user_id: users(:user_one).id, event_id: event.id }
    assert_emails 0 do
      ApplicationMailer.with(params).event_about_to_start.deliver_now
    end
  end
end
