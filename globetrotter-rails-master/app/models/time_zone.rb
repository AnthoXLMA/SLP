class TimezoneNotFound < StandardError; end

class TimeZone < NonPersistent
  attr_reader :country_code, :zone_identifier

  def self.all
    @all ||= TZInfo::Country.all_codes.flat_map do |country_code|
      TZInfo::Country.get(country_code).zone_identifiers.map do |zone_identifier|
        TimeZone.new(zone_identifier, country_code)
      end
    end
  end

  def initialize(zone_identifier, country_code)
    @zone_identifier = zone_identifier
    @country_code = country_code
  end

  def zone_friendly_identifier
    tzinfo.friendly_identifier(true)
  end

  def tzinfo
    @tzinfo ||= TZInfo::Timezone.get(@zone_identifier)
    raise TimezoneNotFound, "Fail to find #{@zone_identifier}" unless @tzinfo

    @tzinfo
  end

  def friendly_identifier
    "#{I18n.t("country.#{country_code}")} - #{zone_friendly_identifier}"
  end
end
