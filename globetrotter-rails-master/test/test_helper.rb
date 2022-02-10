# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require 'minitest/mock'

module Zoom
  class TestResponse
    attr_reader :body

    def initialize(body, success)
      @success = success
      @body = body
    end

    def success?
      @success
    end
  end

  def self.test_response(body, success:)
    TestResponse.new(body, success)
  end

  module API
    def self.connection
      $connection ||= Minitest::Mock.new
    end

    def with_connection
      yield Zoom::API.connection
    end
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    setup do
      @next_event_refreshed ||= NextEvent.refresh
      I18n.locale = 'en'
      Rails.application.routes.default_url_options[:locale] = I18n.locale
    end

    class << self
      def install_test_mail(config)
        test_name = "#{config.fetch(:mailer_method)}_#{config.fetch(:locale)}"
        test test_name do
          user = instance_eval(&config.fetch(:user))
          user.language = config.fetch(:locale)
          user.save!

          # Create the email and store it for further assertions
          params = instance_eval(&config.fetch(:params))
          email = if config[:using_with]
                    self.class.mailer_class.with(params).send(config.fetch(:mailer_method).to_s)
                  else
                    self.class.mailer_class.send(config.fetch(:mailer_method).to_s, *params)
                  end

          # Send the email, then test that it got queued
          assert_emails 1 do
            email.deliver_now
          end

          unless config[:ignore_fixture]
            if email.html_part || email.body
              fixture_filename = File.join(Rails.root, 'test', 'fixtures', self.class.mailer_class.name.underscore,
                                           "#{test_name}.html")
              File.write(fixture_filename, (email.html_part || email).body.to_s)
            end

            if email.text_part
              fixture_filename = File.join(Rails.root, 'test', 'fixtures', self.class.mailer_class.name.underscore,
                                           "#{test_name}.txt")
              File.write(fixture_filename, email.text_part.body.to_s)
            end
          end

          # Test the body of the sent email contains what we expect it to
          assert_equal ['no-reply@theglobetrotters.live'], email.from
          assert_equal [user.email], email.to
          assert_equal config.fetch(:email_title)[config.fetch(:locale).to_sym], email.subject
          assert !(email.html_part || email.text_part || email.body).nil?

          unless config[:ignore_fixture]
            if email.html_part || email.body
              assert_equal read_fixture("#{test_name}.html").join,
                           (email.html_part || email).body.to_s
            end
            assert_equal read_fixture("#{test_name}.txt").join, email.text_part.body.to_s if email.text_part
          end
        end
      end
    end

    def assert_valid_html
      doc = Nokogiri::HTML(response.body)
      if doc.errors.any?
        response_with_line_ids = response.body
                                         .split("\n")
                                         .map
                                         .with_index { |l, i| "#{(i + 1).to_s.ljust(5)} #{l}" }
                                         .join("\n")
        assert false, "html errors: #{doc.errors}\n#{response_with_line_ids}"
      end
    end

    def teardown
      assert_valid_html if respond_to?(:response) && response&.body
    end
  end
end
