# frozen_string_literal: true

require 'test_helper'

class TimeZoneTest < ActiveSupport::TestCase
  test 'it lists all timezone' do
    assert(TimeZone.all.size > 100)
  end

  test 'a timezone object as a friendly name' do
    berlin = TimeZone.all.find { |c| c.zone_identifier == 'Europe/Berlin' }
    catamarca = TimeZone.all.find { |c| c.zone_identifier == 'America/Argentina/Catamarca' }
    I18n.with_locale('fr') do
      assert_equal 'Allemagne - Berlin', berlin.friendly_identifier
      assert_equal 'Argentine - Catamarca, Argentina', catamarca.friendly_identifier
    end
    I18n.with_locale('en') do
      assert_equal 'Germany - Berlin', berlin.friendly_identifier
      assert_equal 'Argentina - Catamarca, Argentina', catamarca.friendly_identifier # a bit strange, to fix ?
    end
  end
end
