# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  FROM = 'no-reply@theglobetrotters.live'
  FROM_CN = 'theGlobetrotters.live'

  helper ApplicationHelper
  default from: "#{FROM_CN} <#{FROM}>"
  layout 'mailer'

  def event_registration
    @user = User.find params[:user_id]
    I18n.with_locale(@user.language || 'en') do
      @event = Event.includes(tour: [{ image_attachment: :blob }, { guide: :user }]).find(params[:event_id])
      attachments['invite.ics'] = {
        transfer_encoding: :base64,
        content: Base64.encode64(ics_confirmation(@event))
      }
      mail(to: @user.email, subject: t('application_mailer.event_registration'))
    end
  end

  def event_cancellation
    @event_registration = EventRegistration.includes([:user, { event: :tour }]).find(params[:event_registration_id])
    I18n.with_locale(@event_registration.user.language || 'en') do
      @event = @event_registration.event
      attachments['invite.ics'] = {
        transfer_encoding: :base64,
        content: Base64.encode64(ics_cancellation(@event))
      }

      @alternate_events_sameevent = Event.includes(:tour)
                                         .where(cancelled_date: nil, tour_id: @event.tour_id)
                                         .where('date > ?', Time.now)
                                         .first(5)

      approx = 30.minutes
      @alternate_events_samedate = Event.includes(:tour)
                                        .where(cancelled_date: nil)
                                        .where('date > ?', Time.now)
                                        .where('date >= ? and date <= ?', @event.date - approx, @event.date + approx)
                                        .where.not(id: @alternate_events_sameevent.map(&:id))
                                        .order(:date)
                                        .first(20)
                                        .uniq(&:tour_id)
                                        .first(5)

      mail(to: @event_registration.user.email, subject: t('application_mailer.event_cancellation'))
    end
  end

  def event_about_to_start
    @user = User.find(params[:user_id])
    I18n.with_locale(@user.language || 'en') do
      @event = Event.includes(:tour).find(params[:event_id])
      if @event.cancelled?
        Rails.logger.info "Skip mail because event #{params[:event_id]} is cancelled"
        return
      end

      mail(to: @user.email, subject: t('application_mailer.event_about_to_start'))
    end
  end

  def event_scheduled
    @event = Event.includes(tour: [{ image_attachment: :blob }, { guide: :user }]).find(params[:event_id])
    @guide = @event.tour.guide
    I18n.with_locale(@guide.user.language || 'en') do
      attachments['invite.ics'] = {
        transfer_encoding: :base64,
        content: Base64.encode64(ics_scheduled(@event))
      }
      mail(to: @guide.user.email, subject: t('application_mailer.event_scheduled'))
    end
  end

  def event_unscheduled
    @event = Event.includes(tour: [{ image_attachment: :blob }, { guide: :user }]).find(params[:event_id])
    @guide = @event.tour.guide
    I18n.with_locale(@guide.user.language || 'en') do
      attachments['invite.ics'] = {
        transfer_encoding: :base64,
        content: Base64.encode64(ics_unscheduled(@event))
      }
      mail(to: @guide.user.email, subject: t('application_mailer.event_unscheduled'))
    end
  end

  private

  def ics_confirmation(event)
    _ics_invite(event, :confirmed)
  end

  def ics_cancellation(event)
    _ics_invite(event, :cancelled)
  end

  def ics_scheduled(event)
    _ics_invite(event, :scheduled)
  end

  def ics_unscheduled(event)
    _ics_invite(event, :unscheduled)
  end

  def description_for_globetrotter(event)
    t('mail.event_confirmation.description', url: event_url(event),
                                             live_before_event_in_minutes: Event::LIVE_BEFORE_EVENT_IN_MINUTES)
  end

  def description_for_guide(event)
    t('mail.event_scheduled.description', url: event_url(event),
                                          minutes: Event::BOOK_ZOOM_LICENSE_BEFORE_EVENT_IN_MINUTES)
  end
  ICS_PROPERTIES = {
    confirmed: {
      sequence: 1,
      status: 'CONFIRMED',
      method: nil,
      description: :description_for_globetrotter,
      reminder: Event::LIVE_BEFORE_EVENT_IN_MINUTES,
      url: :event_url
    },
    cancelled: {
      sequence: 2,
      status: 'CANCELLED',
      method: ['METHOD:CANCEL'],
      description: :description_for_globetrotter,
      reminder: Event::LIVE_BEFORE_EVENT_IN_MINUTES,
      url: :event_url
    },
    scheduled: {
      sequence: 1,
      status: 'CONFIRMED',
      method: nil,
      description: :description_for_guide,
      reminder: Event::BOOK_ZOOM_LICENSE_BEFORE_EVENT_IN_MINUTES,
      url: :guide_event_url
    },
    unscheduled: {
      sequence: 2,
      status: 'CANCELLED',
      method: ['METHOD:CANCEL'],
      description: :description_for_guide,
      reminder: Event::BOOK_ZOOM_LICENSE_BEFORE_EVENT_IN_MINUTES,
      url: :guide_event_url
    }
  }
  def _ics_invite(event, status)
    language = I18n.locale
    properties = ICS_PROPERTIES[status]
    fdate = event.date.utc.strftime('%Y%m%dT%H%M%SZ')
    fdate_end = (event.date + event.tour.duration).utc.strftime('%Y%m%dT%H%M%SZ')
    description = send(properties[:description], event)
    url = send(properties[:url], event)
    [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//theglobetrotters.live//ical//EN',
      'NAME:theGlobetrotters.live',
      'X-WR-CALNAME:theGlobetrotters.live',
      *properties[:method],
      'BEGIN:VEVENT',
      "ORGANIZER;CN=#{FROM_CN}:mailto:#{FROM}",
      "DESCRIPTION;LANGUAGE=#{language}:#{description}",
      "UID:#{event.id}.tour.theglobetrotters.live",
      "SUMMARY;LANGUAGE=#{language}:theGlobetrotters.live: #{event.tour.title}",
      "STATUS:#{properties[:status]}",
      "SEQUENCE:#{properties[:sequence]}",
      "DTSTAMP:#{fdate}",
      "DTSTART:#{fdate}",
      "DTEND:#{fdate_end}",
      "URL:#{url}",
      'END:VEVENT',
      'BEGIN:VALARM',
      'DESCRIPTION:REMINDER',
      "TRIGGER;RELATED=START:-PT#{properties[:reminder]}M",
      'ACTION:DISPLAY',
      'END:VALARM',
      "END:VCALENDAR\r\n"
    ].join("\r\n")
  end

  def default_url_options
    super.merge(locale: I18n.locale)
  end
end
