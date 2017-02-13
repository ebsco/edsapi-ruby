require 'ebsco/version'
require 'ebsco/session'
require 'ebsco/info'
require 'ebsco/results'
require 'ebsco/record'
require 'ebsco/error'
require 'ebsco/http_exception'

module EBSCO
  EDS_API_BASE = 'https://eds-api.ebscohost.com'
  UID_AUTH_URL = '/authservice/rest/uidauth'
  IP_AUTH_URL = '/authservice/rest/ipauth'
  CREATE_SESSION_URL = '/edsapi/rest/CreateSession'
  END_SESSION_URL = '/edsapi/rest/EndSession'
  INFO_URL = '/edsapi/rest/Info'
  SEARCH_URL = '/edsapi/rest/Search'
  RETRIEVE_URL = '/edsapi/rest/Retrieve'
  USER_AGENT = 'EBSCO EDS GEM v0.0.1'
  INTERFACE_ID =
  LOG = 'faraday.log'
  MAX_ATTEMPTS = 2

end
