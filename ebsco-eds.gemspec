# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ebsco/eds/version'

Gem::Specification.new do |spec|
  spec.name          = 'ebsco-eds'
  spec.version       = EBSCO::EDS::VERSION
  spec.authors       = ['Bill McKinney','Eric Frierson']
  spec.email         = ['bmckinney@ebsco.com, efrierson@ebsco.com']
  spec.summary       = 'Summary: EBSCO EDS API'
  spec.description   = 'Description: EBSCO EDS API'
  spec.homepage      = 'https://github.com/ebsco/edsapi-ruby'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.files        += Dir.glob('lib/**/*')
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.4'

  spec.add_dependency 'faraday', '~> 0'
  spec.add_dependency 'faraday-detailed_logger', '~> 2.0'
  spec.add_dependency 'faraday_middleware', '~> 0.11'
  spec.add_dependency 'dotenv', '~> 2.2'
  spec.add_dependency 'climate_control', '~> 0'
  spec.add_dependency 'require_all', '~> 2.0'
  spec.add_dependency 'bibtex-ruby', '~> 5.1', '>= 5.1.0'
  spec.add_dependency 'citeproc', '>= 1.0.4', '< 2.0'
  spec.add_dependency 'csl', '~> 1.4'
  spec.add_dependency 'citeproc-ruby', '~> 1.0', '>= 1.0.2'
  spec.add_dependency 'csl-styles', '~> 1.0', '>= 1.0.1.5'
  spec.add_dependency 'activesupport', '~> 5.2'
  spec.add_dependency 'net-http-persistent', '~> 3.1'
  spec.add_dependency 'sanitize', '~> 5.0'
  spec.add_dependency 'public_suffix', '~>4.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'simplecov', '~> 0.17.0'
  spec.add_development_dependency 'codecov', '~> 0.1'
  spec.add_development_dependency 'vcr', '~> 5.0', '>= 5.0.0'
  spec.add_development_dependency 'minitest-vcr', '~> 1.4', '>= 1.4.0'
  spec.add_development_dependency 'webmock', '~> 3.6'

end
