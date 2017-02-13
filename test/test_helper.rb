require 'dotenv'
require 'climate_control'
require 'simplecov'

Dotenv.load('.env.test')
SimpleCov.start do
  add_filter 'test'
  command_name 'Mintest'
end

# require 'codecov'
# SimpleCov.formatter = SimpleCov::Formatter::Codecov
# CODECOV_TOKEN='cfc86a29-02eb-43f3-9903-7fd46f9a510d'

require 'minitest/autorun'
require 'ebsco'