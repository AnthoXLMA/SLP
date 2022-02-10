# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require_relative 'seeds/countries'

class ZoomLicenseSeed
  include Zoom::API
  def initialize
    user_ids = users['users'].map { |u| u['id'] }
    existing_zoom_user_ids = ZoomLicense.pluck(:zoom_user_id)
    (user_ids - existing_zoom_user_ids).each { |id| ZoomLicense.create(zoom_user_id: id) }
  end
end

ZoomLicenseSeed.new
license_id = ZoomLicense.first.id

users = YAML.safe_load(File.read('db/seeds/users.yml'))
db_users = users.map do |u|
  email = u.delete('email') || "#{u['firstname']}.#{u['lastname']}@globetrotter.live".downcase
  puts "creating user with email: #{email}"
  db_user = User.find_by(email: email) || User.new(email: email, password: SecureRandom.alphanumeric)
  db_user.instance_variable_set(:@strict_loading, false)
  image = u.delete('image')
  guide = u.delete('guide')
  db_user.update(u)
  db_user.language ||= 'fr'
  db_user.tour_language ||= []
  db_user.tour_language.compact!
  db_user.tour_language.push 'fr' if db_user.tour_language.empty?
  if guide
    if db_user.guide
      db_user.guide.update(guide)
    else
      db_user.build_guide guide
    end
    if image
      db_user.guide.image_attachment&.instance_variable_set(:@strict_loading, false)
      db_user.guide.image.attach(
        io: File.open(File.join('db/seeds', image)),
        filename: image,
        content_type: 'image/webp'
      )
    end
    db_user.save!
    db_user.guide.save!
  end
  db_user.save!
  db_user
end.group_by(&:firstname)

countries_by_code = seed_countries.group_by(&:code)
puts countries_by_code.inspect

tours = YAML.safe_load(File.read('db/seeds/tours.yml'))
tours.each do |data|
  puts "Tour: #{data['title']}"
  id = data.delete('id')
  image = data.delete('image')
  duration_min = data.delete('duration_min')
  data[:duration] = duration_min.minutes
  country_code = data.delete('country')
  data['country'] = countries_by_code.fetch(country_code)&.first
  t = Tour.find_or_initialize_by(id: id)
  t.instance_variable_set(:@strict_loading, false)
  guide_firstname = data.delete('guide')
  guide = db_users[guide_firstname]&.first
  raise "No guide #{guide_firstname}" unless guide

  data[:guide_id] = guide.guide.id
  t.update(data)

  t.image_attachment&.instance_variable_set(:@strict_loading, false)
  t.image.attach(
    io: File.open(File.join('db/seeds', image.sub(/.webp$/, '_norm.webp'))),
    filename: image,
    content_type: 'image/webp'
  )
  t.thumbnail_attachment&.instance_variable_set(:@strict_loading, false)
  t.thumbnail.attach(
    io: File.open(File.join('db/seeds', image.sub(/.webp$/, '_small.webp'))),
    filename: image,
    content_type: 'image/webp'
  )
  t.published = true
  t.save!

  today = Date.today
  events = Array.new(10) do |i|
    { tour_id: t.id, date: today + (1 + 5 * i).day + ((i * 5 + 2 * t.id) % 24).hour, zoom_license_id: license_id }
  end
  events.each do |e|
    Event.find_or_create_by!(e)
  rescue StandardError => ex
    puts "create event #{e} failed with #{ex.class}:#{ex.message}"
  end
  RefreshMaterializedViewsJob.perform_later
end

comments = YAML.safe_load(File.read('db/seeds/comments.yml'))
comments.each do |comment|
  puts "comment: #{comment}"
  tour = Tour.find_by(title: comment.fetch('tour'))
  user = User.find_by(firstname: comment.fetch('user'))
  puts "adding comment to #{tour&.title} for #{user&.firstname}"
  event = Event.joins(:tour).where(tour: { id: tour.id }).first
  next unless event

  event_registration = EventRegistration.find_or_create_by!(event_id: event.id, user_id: user.id)
  Comment.find_or_create_by!(event_registration: event_registration, rating: comment.fetch('rating'),
                             comment: comment.fetch('comment'))
end

ActiveRecord::Base.connection.tables.each do |t|
  ActiveRecord::Base.connection.reset_pk_sequence!(t)
end
