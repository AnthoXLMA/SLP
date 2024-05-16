# -*- encoding: utf-8 -*-
# stub: omniauth 1.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "omniauth".freeze
  s.version = "1.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Bleigh".freeze, "Erik Michaels-Ober".freeze]
  s.date = "2012-03-06"
  s.description = "A generalized Rack framework for multiple-provider authentication.".freeze
  s.email = ["michael@intridea.com".freeze, "sferik@gmail.com".freeze]
  s.homepage = "http://github.com/intridea/omniauth".freeze
  s.rubygems_version = "3.2.26".freeze
  s.summary = "A generalized Rack framework for multiple-provider authentication.".freeze

  s.installed_by_version = "3.2.26" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rack>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<hashie>.freeze, ["~> 1.2"])
    s.add_development_dependency(%q<growl>.freeze, [">= 0"])
    s.add_development_dependency(%q<guard>.freeze, [">= 0"])
    s.add_development_dependency(%q<guard-bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<guard-rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_development_dependency(%q<rack-test>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<rb-fsevent>.freeze, [">= 0"])
    s.add_development_dependency(%q<rdiscount>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 2.8"])
    s.add_development_dependency(%q<yard>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rack>.freeze, [">= 0"])
    s.add_dependency(%q<hashie>.freeze, ["~> 1.2"])
    s.add_dependency(%q<growl>.freeze, [">= 0"])
    s.add_dependency(%q<guard>.freeze, [">= 0"])
    s.add_dependency(%q<guard-bundler>.freeze, [">= 0"])
    s.add_dependency(%q<guard-rspec>.freeze, [">= 0"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_dependency(%q<rack-test>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rb-fsevent>.freeze, [">= 0"])
    s.add_dependency(%q<rdiscount>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 2.8"])
    s.add_dependency(%q<yard>.freeze, [">= 0"])
  end
end
