# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html). 

## [1.0.8] - 2019-07-09
### Fixed
- Throws error when query fails with a 200 status code and html error message (query = `the meaning of life or 4=2`), see #90.
- Raises a specific "record not found" error instead of a generic "bad request" error when a record cannot be retrieved, see #88.

## [1.0.7] - 2018-12-05
### Changed
- logger dependency removed since it's been part of the standard library.

## [1.0.6] - 2018-11-14
### Fixed
- Fixed a bug where the cached auth key isn't deleted if it expires before its cache expiration. This should only occur in rare cases where the auth token cache expiration exceeds 30 minutes.
### Added
- Cache expiration is configurable for individual EDS API calls (time unit = seconds).
### Changed
- Default cache expiration for auth keys is now 25 minutes instead of 30 to make sure they are always refreshed before their 30 minute expiration. If an expiration is configured longer than 25 minutes, it is reset to 25 minutes automatically.

## [1.0.5] - 2018-11-02
### Fixed
- Fixed a bug where fulltext html becomes nil after sanitizing. [#85](https://github.com/ebsco/edsapi-ruby/issues/85) 
- Fixed a bug where the url protocol is missing from fulltext custom links. [#86](https://github.com/ebsco/edsapi-ruby/issues/86)

## [1.0.4] - 2018-10-29
### Fixed
- List retrieval returns a repeating list of just the first record. 
- List retrieval fails to increment the EDS result id.

## [1.0.3] - 2018-10-18
### Changed
- Citation style and export links can now be removed entirely or replaced by specifying regular expressions in several configuration options that can include ruby erb variable expressions for an item's `dbid` and `an`. This was added to address situations where customer proxy urls are returned. See: [Citation link replacement](https://github.com/ebsco/edsapi-ruby/wiki/Citation-link-replacement)

## [1.0.2] - 2018-10-15
### Added
- EBSCOhost links are removed from citation styles and exports by default

## [1.0.1] - 2018-10-10
### Added
- Citation styles/exports are added to Records
- Retrieve citation styles/exports for a Record ID or list of Record IDs
- Retrieve a list of available citation styles/exports from Info
- Citation styles/exports available in guest mode
### Fixed
- Double-unescapes data with an ephtml section (sul-dlss/SearchWorks #1504)
- Adds searchlinks to subject items when they don't exist #80 (sul-dlss/SearchWorks #1791)
### Changed
- Updates test cassettes with new citation styles/exports API calls

## [1.0.0] - 2018-03-05
### Changed
- Increments version to reflect production ready status

## [0.3.19.pre] - 2018-03-05
### Added
- Optionally (default=off) include quick view images with Records
### Changed
- Reorganizes VCR tests

## [0.3.18.pre] - 2017-10-10
### Fixed
- Fixes session config bug #84

## [0.3.17.pre] - 2017-09-27
### Changed
- Optionally (default=off) titleize facets via `titleize_facets` in config

## [0.3.16.pre] - 2017-09-20
### Added
- Titleize facets
- Autocorrect feature

## [0.3.15.pre] - 2017-09-18
### Added
- Optionally (default=off) converts all searchLink field codes to DE via `all_subjects_search_links` in config
- Optionally (default=off) decodes/sanitizes html in item data and fulltext html via `decode_sanitize_html` in config

## [0.3.14.pre] - 2017-09-14
### Fixed
- Fixes 250+ pagination issues with SourceType and ContentProvider facets

## [0.3.13.pre] - 2017-09-13
### Fixed
- Includes additional Subject and Geographic Subject metadata

## [0.3.12.pre] - 2017-09-11
### Fixed
- Fixes some 250+ pagination issues
### Changed
- Updates tests

## [0.3.11.pre] - 2017-09-06
### Added
- Adds KW (keywords) and SH (subject heading) to solr search fields

[1.0.8]: https://github.com/ebsco/edsapi-ruby/compare/1.0.7...1.0.8
[1.0.7]: https://github.com/ebsco/edsapi-ruby/compare/1.0.6...1.0.7
[1.0.6]: https://github.com/ebsco/edsapi-ruby/compare/1.0.5...1.0.6
[1.0.5]: https://github.com/ebsco/edsapi-ruby/compare/1.0.4...1.0.5
[1.0.4]: https://github.com/ebsco/edsapi-ruby/compare/1.0.3...1.0.4
[1.0.3]: https://github.com/ebsco/edsapi-ruby/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/ebsco/edsapi-ruby/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/ebsco/edsapi-ruby/compare/1.0.0...1.0.1
