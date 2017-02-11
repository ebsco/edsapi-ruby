require 'dotenv'
require 'climate_control'
require 'simplecov'

Dotenv.load('.env.test')
SimpleCov.start do
  add_filter 'test'
  command_name 'Mintest'
end

require 'minitest/autorun'
require 'ebsco'