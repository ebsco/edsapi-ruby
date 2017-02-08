# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ebsco/version'

Gem::Specification.new do |spec|
  spec.name          = 'ebsco'
  spec.version       = EBSCO::VERSION
  spec.authors       = ['Bill McKinney']
  spec.email         = ['bmckinney@ebsco.com']

  spec.summary       = 'Summary: EBSCO EDS API'
  spec.description   = 'Descriptiong: EBSCO EDS API'
  spec.homepage      = 'https://ebsco.com/ruby'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.files        += Dir.glob('lib/**/*')

  spec.add_dependency 'faraday', '~> 0'
  spec.add_dependency 'faraday-detailed_logger', '~> 2.0'
  spec.add_dependency 'faraday_middleware', '~> 0.11'
  spec.add_dependency 'logger', '~> 1.2'
  spec.add_dependency 'dotenv', '~> 0.11'
  spec.add_dependency 'climate_control', '~> 0'

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
end
