require 'eds/version'
require 'eds/session'
require 'eds/info'
require 'eds/results'
require 'eds/record'
require 'eds/error'
require 'eds/http_exception'

module EBSCO

  module EDS
    EDS_API_BASE = 'https://eds-api.ebscohost.com'
    UID_AUTH_URL = '/authservice/rest/uidauth'
    IP_AUTH_URL = '/authservice/rest/ipauth'
    CREATE_SESSION_URL = '/edsapi/rest/CreateSession'
    END_SESSION_URL = '/edsapi/rest/EndSession'
    INFO_URL = '/edsapi/rest/Info'
    SEARCH_URL = '/edsapi/rest/Search'
    RETRIEVE_URL = '/edsapi/rest/Retrieve'
    USER_AGENT = 'EBSCO EDS GEM v0.0.1'
    INTERFACE_ID = 'EBSCO EDS GEM v0.0.1'
    LOG = 'faraday.log'
    MAX_ATTEMPTS = 2
    MAX_RESULTS_PER_PAGE = 100
  end

end