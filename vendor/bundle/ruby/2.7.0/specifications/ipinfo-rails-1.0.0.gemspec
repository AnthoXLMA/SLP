# -*- encoding: utf-8 -*-
# stub: ipinfo-rails 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ipinfo-rails".freeze
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["James Timmins".freeze, "Uman Shahzad".freeze]
  s.date = "2018-12-10"
  s.description = "The official Rails gem for IPinfo. IPinfo prides itself on being the most reliable, accurate, and in-depth source of IP address data available anywhere. We process terabytes of data to produce our custom IP geolocation, company, carrier and IP type data sets. You can visit our developer docs at https://ipinfo.io/developers.".freeze
  s.email = ["jameshtimmins@gmail.com".freeze, "uman@mslm.io".freeze]
  s.homepage = "https://ipinfo.io".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.2.26".freeze
  s.summary = "The official Rails gem for IPinfo. IPinfo prides itself on being the most reliable, accurate, and in-depth source of IP address data available anywhere. We process terabytes of data to produce our custom IP geolocation, company, carrier and IP type data sets. You can visit our developer docs at https://ipinfo.io/developers.".freeze

  s.installed_by_version = "3.2.26" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<IPinfo>.freeze, ["~> 1.0.1"])
    s.add_runtime_dependency(%q<rack>.freeze, ["~> 2.0"])
  else
    s.add_dependency(%q<IPinfo>.freeze, ["~> 1.0.1"])
    s.add_dependency(%q<rack>.freeze, ["~> 2.0"])
  end
end
