# frozen_string_literal: true

require 'csv'

CountriesCSV = File.expand_path('countries.csv', __dir__)

def seed_countries
  CSV.open(CountriesCSV, headers: true) do |csv|
    csv.map do |row|
      puts "Country: #{row.to_h}"
      Country.find_or_create_by!(country: row['Country'], region: row['Region'], code: row['Code'])
    end
  end
end
