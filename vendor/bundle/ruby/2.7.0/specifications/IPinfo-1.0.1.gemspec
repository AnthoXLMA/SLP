# -*- encoding: utf-8 -*-
# stub: IPinfo 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "IPinfo".freeze
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Stanislav K, James Timmins".freeze, "Uman Shahzad".freeze]
  s.bindir = "exe".freeze
  s.date = "2021-01-05"
  s.description = " This is a ruby wrapper for http://ipinfo.io. ".freeze
  s.email = ["jameshtimmins@gmail.com".freeze, "uman@mslm.io".freeze]
  s.homepage = "https://ipinfo.io".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.2.26".freeze
  s.summary = "This is a ruby wrapper for http://ipinfo.io.".freeze

  s.installed_by_version = "3.2.26" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<faraday>.freeze, ["~> 1.0"])
    s.add_runtime_dependency(%q<json>.freeze, ["~> 2.1"])
    s.add_runtime_dependency(%q<lru_redux>.freeze, ["~> 1.1"])
  else
    s.add_dependency(%q<faraday>.freeze, ["~> 1.0"])
    s.add_dependency(%q<json>.freeze, ["~> 2.1"])
    s.add_dependency(%q<lru_redux>.freeze, ["~> 1.1"])
  end
end
