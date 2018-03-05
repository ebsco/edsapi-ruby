<img src="https://discovery.ebsco.com/files/pulse-images/EDS-logo_1LINE.png"/>

A Ruby interface to the EBSCO Discovery Services API.

[![Build Status](https://travis-ci.org/ebsco/edsapi-ruby.svg)](https://travis-ci.org/ebsco/edsapi-ruby)
[![codecov](https://codecov.io/gh/ebsco/edsapi-ruby/branch/master/graph/badge.svg)](https://codecov.io/gh/ebsco/edsapi-ruby/branch/master)
[![Dependency Status](https://gemnasium.com/badges/github.com/ebsco/edsapi-ruby.svg)](https://gemnasium.com/github.com/ebsco/edsapi-ruby)
[![Gem Version](https://img.shields.io/gem/v/ebsco-eds.svg?style=flat)](http://rubygems.org/gems/ebsco-eds)

## Dependencies

* Ruby 2.2+

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ebsco-eds'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ebsco-eds

## Feature Support

- Research Starters are included in results response, when available
- Configurable auto-suggest or 'Did you mean' support
- Configurable auto-correct support
- Quick-view images can be included in results, when available

## Documentation

- [Configuration](https://github.com/ebsco/edsapi-ruby/wiki/Configuration)
- [Quick Start](https://github.com/ebsco/edsapi-ruby/wiki/Quick-Start)
- [Blacklight Support](https://github.com/ebsco/edsapi-ruby/wiki/Solr-and-Blacklight-Support)
- [Citation Formats (Experimental)](https://github.com/ebsco/edsapi-ruby/wiki/Citation-Formats-(Experimental))

### Models

- [Session](https://github.com/ebsco/edsapi-ruby/wiki/Session)
- [Results](https://github.com/ebsco/edsapi-ruby/wiki/Results)
- [Records](https://github.com/ebsco/edsapi-ruby/wiki/Records)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ebsco/edsapi-ruby.

## Development

After checking out the repo, run `bin/setup` to install dependencies. 

You can run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 

#### Running the tests
- `git clone git://github.com/ebsco/edsapi-ruby && cd edsapi-ruby`
- `bundle`
- Create a `.env.test` file
  - It should look like the following:
```ruby
EDS_PROFILE=profile_name
EDS_GUEST=n
EDS_USER=your_user_id
EDS_PASS=secret
EDS_AUTH=ip
EDS_ORG=your_institution
```
- `rake test`

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
