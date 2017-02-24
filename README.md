# EBSCO Discovery Service Ruby Gem

A Ruby interface to the EBSCO Discovery Services API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ebsco-eds'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ebsco-eds

## Configuration

### EDS API Profile

You'll need to have an EDS API profile in EBSCOadmin. You can request this at eds@ebscohost.com, or you can create a 
new EDS API profile yourself using the _Profile Maintenance_ feature. 

Be sure you add content to your EDS API profile (via the _Databases_ tab) so it will return results.

### Authentication

An EDS API session requires authentication. There are two methods available and both are configured in EBSCOadmin:

#### 1. IP address

- Use this if you plan to access the API from server(s) with a fixed IP address, or via a proxy server.
- Create and manage IP address lists in the top-level _Authentication_ tab at the top of the EBSCOadmin screen and 
select the _IP Address_ sub-tab.

#### 2. User ID and password

- Use this if you might connect to the API from machines outside your network, or from many different addresses.
- Create a user ID and password to access your API profile in the _Authentication_ tab at the top of the EBSCOadmin screen. 
Make sure the _Group_ associated with the login you create is the group that contains your EDS API profile. 

EBSCO Support (eds@ebscohost.com) can help you set up an EDS API profile and get a userID and password for it if you are unfamiliar with EBSCOadmin.

### Session

You can configure the EDS session in two ways:

#### 1. Using environment variables

```
EDS_PROFILE=profile_name
EDS_GUEST=n
EDS_USER=your_user_id
EDS_PASS=secret
EDS_AUTH=ip
EDS_ORG=your_institution
```
Once set, you create a session like this:

```ruby
session = EBSCO::EDS::Session.new
```

#### 2. Using an options hash

```ruby
session = EBSCO::EDS::Session.new({
      :profile =>'eds-api', :
      :user =>'your_user_id', 
      :pass =>'secret', 
      :guest => false, 
      :org => 'my organization'})
```
## QuickStart

Install and load ebsco-eds in an IRB session:

```ruby
$ [sudo] gem install ebsco-eds
$ irb
>> require 'ebsco/eds'
```

Create a session:

```ruby
session = EBSCO::EDS::Session.new({:user=>'user', :pass=>'secret', :profile=>'edsapi'})
```

Perform a simple search:

```ruby
results = session.simple_search('volcano')
results.stat_total_hits
 => 1519176 
```

Get a search result:
```ruby
record = results.records.first
record.title
 => "Turmoil at Turrialba Volcano (Costa Rica): Degassing and eruptive processes inferred from high-frequency gas monitoring" 
record.plink
 => "http://search.ebscohost.com/login.aspx?direct=true&site=eds-live&db=edsswe&AN=edsswe.oai.publications.lib.chalmers.se.245269" 
```

Retrieve a record by database ID and accession number:

```ruby
record = session.retrieve({dbid: 'asn', an: '112761583'})
record.title
 => "What Makes a Story." 
```

## Models

### Session

#### Search and Retrieve Methods

**add_actions(actions)**

Add actions to an existing search session.

```ruby
results = session.add_actions('addfacetfilter(SubjectGeographic:massachusetts)')
```

**add_query(query)**

Add a query to the search request. When a query is added, it will be assigned an ordinal, which will be exposed in the 
search response message. It also removes any specified facet filters and sets the page number to 1.

```ruby 
results = session.add_query('AND,California')
```

**clear_queries()**

Clears all queries and facet filters, and set the page number back to 1; limiters and expanders are not modified. 

**clear_search()**

Clear all specified query expressions, facet filters, limiters and expanders, and set the page number back to 1.

**end()**

Invalidates the session token. End Session should be called when you know a user has logged out.

**remove_query(query_id)**

Removes query from the currently specified search. It also removes any specified facet filters and sets the page 
number to 1.

```ruby
results = session.remove_query(1)
```
**retrieve(dbid:, an:, highlight: nil, ebook: 'ebook-pdf')**

Returns a Record based a particular result based on a database ID and accession number.

Attributes:
- :dbid - The database ID (required).
- :an - The accession number (required).
- :highlight - Comma separated list of terms to highlight in the data records (optional).
- :ebook - Preferred format to return ebook content in. Either ebook-pdf (default) or ebook-pdf.

```ruby
record = session.retrieve({dbid: 'asn', an: '108974507'})
```

**search(options = {}, add_actions = false)**

Performs a search.

Options:
- :query - Required. The search terms. Format: {booleanOperator},{fieldCode}:{term}. Example: SU:Hiking
- :mode - Search mode to be used. Either: all (default), any, bool, smart
- :results_per_page - The number of records retrieved with the search results (between 1-100, default is 20).
- :page - Starting page number for the result set returned from a search (if results per page = 10, and page number = 3 , this implies: I am expecting 10 records starting at page 3).
- :sort - The sort order for the search results. Either: relevance (default), oldest, newest
- :highlight - Specifies whether or not the search term is highlighted using <highlight /> tags. Either true or false.
- :include_facets - Specifies whether or not the search term is highlighted using <highlight /> tags. Either true (default) or false.
- :facet_filters - Facets to apply to the search. Facets are used to refine previous search results. Format: {filterID},{facetID}:{value}[,{facetID}:{value}]* Example: 1,SubjectEDS:food,SubjectEDS:fiction
- :view - Specifies the amount of data to return with the response. Either 'title': title only; 'brief' (default): Title + Source, Subjects; 'detailed': Brief + full abstract
- :actions - Actions to take on the existing query specification. Example: addfacetfilter(SubjectGeographic:massachusetts)
- :limiters - Criteria to limit the search results by. Example: LA99:English,French,German
- :expanders - Expanders that can be applied to the search. Either: thesaurus, fulltext, relatedsubjects
- :publication_id - Publication to search within.
- :related_content - Comma separated list of related content types to return with the search results. Either 'rs' (Research Starters) or 'emp' (Exact Publication Match)
- :auto_suggest - Specifies whether or not to return search suggestions along with the search results. Either true or false (default).

```ruby
results = session.search({query: 'abraham lincoln', results_per_page: 5, related_content: ['rs','emp']})
results = session.search({query: 'volcano', results_per_page: 1, publication_id: 'eric', include_facets: false})
```

**simple_search(query)**

Performs a simple search. All other search options assume default values.

Attributes: 
- query - the search query.

```ruby
results = session.simple_search('volcanoes') 
```

**Getting Auto-Suggest Terms**

If you turn on auto_suggest, you can retrieve auto-suggest or "did you mean" terms in this way:

```ruby
results = session.search({query: 'string thery', auto_suggest: true})
results.did_you_mean
 => "string theory"
```

#### Setter Methods

Use these methods to apply new configuration settings to an existing search.

**include_related_content(val)**

A related content type to additionally search for and include with the search results.

```ruby
results = session.include_related_content('rs')
```

**results_per_page(num)**

Sets the page size on the search request.

```ruby
results = session.results_per_page(50)
```

**set_highlight(val)**

Sets whether or not to turn highlighting on or off (y|n).

```ruby
results = session.set_highlight('n')
```

**set_include_facets(val)**

Specify to include facets in the results or not. Either 'y' or 'n'.

```ruby
results = session.set_include_facets('n')
```

**set_search_mode(mode)**

Sets the search mode. The available search modes are returned from the info method.

```ruby
results = session.set_search_mode('bool')
```

**set_sort(val)**

Sets the sort for the search. The available sorts for the specified databases can be obtained from the session’s info 
attribute. Sets the page number back to 1.

```ruby
results = session.set_sort('newest')
```

**set_view(view)**

Specifies the view parameter. The view representes the amount of data to return with the search.

```ruby
results = session.set_view('detailed')
```

#### Publication Methods

**add_publication(pub_id)**

Specifies a publication to search within. Sets the pages number back to 1.

```ruby
results = session.add_publication('eric')
```

**remove_all_publications()**

Removes all publications from the search. Sets the page number back to 1.

**remove_publication(pub_id)**

Removes a publication from the search. Sets the page number back to 1.

```ruby
results = session.remove_publication('eric')
```

#### Profile Query Methods

**dbid_in_profile(dbid)**

Determine if a database ID is available in the profile. Returns Boolean.

**get_available_database_ids()**

Get a list of all available database IDs. Returns Array of IDs.

```ruby
session.get_available_database_ids
 => ["nlebk", "e000xna", "edsart", "e700xna", "cat02060a", "ers", "asn"] 
```

**publication_match_in_profile()**

Determine if publication matching is available in the profile. Returns Boolean.

**research_starters_match_in_profile()**

Determine if research starters are available in the profile. Returns Boolean.

#### Pagination Methods

**get_page(page = 1)**

Get a specified page of results Returns search Results.

**move_page(num)**

Increments the current results page number by the value specified. If the current page was 5 and the specified value 
was 2, the page number would be set to 7.

**next_page()**

Get the next page of results.

**prev_page()**

Get the previous page of results.

**reset_page()**

Get the first page of results.

#### Limiter Methods

**add_limiter(id, val)**

Adds a limiter to the currently defined search and sets the page number back to 1.

```ruby
results = session.add_limiter('FT','y')
```

**clear_limiters()**

Clears all currently specified limiters and sets the page number back to 1.

**remove_limiter(id)**

Removes the specified limiter and sets the page number back to 1.

```ruby
results = session.remove_limiter('FT')
```

**remove_limiter_value(id, val)**

Removes a specified limiter value and sets the page number back to 1.

```ruby
results = session.remove_limiter_value('LA99','French')
```

#### Facet Methods

**add_facet(facet_id, facet_val)**

Adds a facet filter to the search request. Sets the page number back to 1.

```ruby
results = session.add_facet('Publisher', 'wiley-blackwell')
results = session.add_facet('SubjectEDS', 'water quality')
```

**clear_facets()**

Removes all specified facet filters. Sets the page number back to 1.

**remove_facet(group_id)**

Removes a specified facet filter id. Sets the page number back to 1.

```ruby
results = session.remove_facet(45)
```

**remove_facet_value(group_id, facet_id, facet_val)**

Removes a specific facet filter value from a group. Sets the page number back to 1.

```ruby
results = session.remove_facet_value(2, 'DE', 'Psychology')
```

#### Expander Methods

**add_expander(val)**

Adds expanders and sets the page number back to 1. Multiple expanders should be comma separated.

```ruby
results = session.add_expander('thesaurus,fulltext')
```

**clear_expanders()**

Removes all specified expanders and sets the page number back to 1.

**remove_expander(val)**

Removes a specified expander. Sets the page number to 1.

```ruby
results = session.remove_expander('fulltext')
```

### Results

#### Attributes

**publication_match[R]**

Array of EBSCO::EDS::Record Exact Publication Matches.

**records[R]**

Array of EBSCO::EDS::Record results.

**research_starters[R]**

Array of EBSCO::EDS::Record Research Starters.

**results[R]**

Raw search results as a hash.

#### Methods

**applied_expanders()**

Expanders applied to the search.

```ruby
[
   {"Id"=>"fulltext", "RemoveAction"=>"removeexpander(fulltext)"},
   {"Id"=>"thesaurus", "RemoveAction"=>"removeexpander(thesaurus)"},
   {"Id"=>"relatedsubjects", "RemoveAction"=>"removeexpander(relatedsubjects)"}
 ]
```

**applied_facets()**

List of facets applied to the search.

```ruby
[{
   "FacetValue"=>{"Id"=>"SubjectGeographic", "Value"=>"massachusetts"},
   "RemoveAction"=>"removefacetfiltervalue(1,SubjectGeographic:massachusetts)"
 }]
```

**applied_limiters()**

List of limiters applied to the search.

```ruby
[{
   "Id"=>"LA99",
   "LimiterValuesWithAction"=>[{"Value"=>"French", "RemoveAction"=>"removelimitervalue(LA99:French)"}],
   "RemoveAction"=>"removelimiter(LA99)"
}]
```

**applied_publications()**

Publications search was limited to.

```ruby
[
   ["Id", "eric"],
   ["RemoveAction", "removepublication(eric)"]
]
```

**database_stats()**

Provides a list of databases searched and the number of hits found in each one.

```ruby
[
   {:id=>"nlebk", :hits=>0, :label=>"eBook Collection (EBSCOhost)"},
   {:id=>"e000xna", :hits=>30833, :label=>"eBook Academic Collection (EBSCOhost)"},
   {:id=>"edsart", :hits=>8246, :label=>"ARTstor Digital Library"},
   {:id=>"e700xna", :hits=>6701, :label=>"eBook Public Library Collection (EBSCOhost)"},
   {:id=>"cat02060a", :hits=>3464, :label=>"EDS Demo Catalog – US - U of Georgia"},
   {:id=>"ers", :hits=>1329, :label=>"Research Starters"},
   {:id=>"asn", :hits=>136406, :label=>"Academic Search Ultimate"}
 ]
```

**date_range()**

Returns a hash of the date range available for the search.

```ruby
{:mindate=>"1501-01", :maxdate=>"2018-04", :minyear=>"1501", :maxyear=>"2018"}
```

**did_you_mean()**

Provides alternative search terms to correct spelling, etc.

```ruby
results = session.simple_search('earthquak')
results.did_you_mean
=> "earthquake"
```

**facets(facet_provided_id = 'all')**

Provides a list of facets for the search results.

```ruby
[
   {
     :id=>"SourceType",
     :label=>"Source Type",
     :values=>[
       {
          :value=>"Academic Journals",
          :hitcount=>147,
          :action=>"addfacetfilter(SourceType:Academic Journals)"
       },
       {
          :value=>"News",
          :hitcount=>111,
          :action=>"addfacetfilter(SourceType:News)"
        },

    ...

   }
 ]
```

**page_number()**

Current page number for the results. Returns an integer.

**retrieval_criteria()**

Retrieval criteria that was applied to the search. Returns a hash.

```ruby
{"View"=>"brief", "ResultsPerPage"=>20, "PageNumber"=>1, "Highlight"=>"y"}
```

**search_criteria()**

Search criteria used in the search Returns a hash.

```ruby
{
   "Queries"=>[{"BooleanOperator"=>"AND", "Term"=>"earthquakes"}],
   "SearchMode"=>"all",
   "IncludeFacets"=>"y",
   "Expanders"=>["fulltext", "thesaurus", "relatedsubjects"],
   "Sort"=>"relevance",
   "RelatedContent"=>["rs"],
   "AutoSuggest"=>"n"
 }
```

**search_criteria_with_actions()**

Search criteria actions applied. Returns a hash.

```ruby
{
   "QueriesWithAction"=>[{"Query"=>{"BooleanOperator"=>"AND", "Term"=>"earthquakes"}, "RemoveAction"=>"removequery(1)"}],
   "ExpandersWithAction"=>[{"Id"=>"fulltext", "RemoveAction"=>"removeexpander(fulltext)"}]
}
```

**search_queries()**

Queries used to produce the results. Returns an array of query hashes.

```ruby
[{"BooleanOperator"=>"AND", "Term"=>"volcano"}]
```

**search_terms()**

Returns a simple list of the search terms used. Boolean operators are not indicated.

```ruby
["earthquakes", "california"]
```

**stat_total_hits()**

Total number of results found.

**stat_total_time()**

Time it took to complete the search in milliseconds.

### Records

#### Attributes

**record[RW]**

Raw record as returned by the EDS API via search or retrieve

#### Methods

**abstract()**

The abstract

**access_level()**

The access level.

**accession_number()**

The accession number.

**all_links()**

A list of all available links.

**author_affiliations()**

The author affiliations

**author_supplied_keywords()**

Author supplied keywords

**authors()**

The list of authors

**cover_medium_url()**

Cover image - medium size link

**cover_thumb_url()**

Cover image - thumbnail size link

**covers()**

Cover images

**database_id()**

The database ID.

**database_name()**

The database name or label.

**document_type()**

Document type.

**doi()**

DOI identifier.

**fulltext_link()**

The first fulltext link.

**fulltext_links()**

All available fulltext links.

**fulltext_word_count()**

Word count for fulltext.

**html_fulltext()**

Fulltext.

**images(size_requested = 'all')**

List of cover images.

**isbn_electronic()**

Electronic ISBN

**isbn_print()**

Print ISBN

**isbns()**

List of ISBNs

**issn_print()**

Prind ISSN

**issns()**

List of ISSNs

**issue()**

Issue

**languages()**

Languages

**non_fulltext_links()**

All available non-fulltext links.

**notes()**

Notes

**oclc()**

OCLC identifier.

**other_titles()**

Other alternative titles.

**page_count()**

Total number of pages.

**page_start()**

Starting page number.

**physical_description()**

Physical description.

**plink()**

EBSCO's persistent link.

**publication_date()**

Publication date.

**publication_type()**

Publication type.

**publication_type_id()**

Publication type ID.

**publication_year()**

Publication year.

**publisher_info()**

Publisher information.

**relevancy_score()**

The search relevancy score.

**result_id()**

Result ID.

**retrieve_options()**

Options hash containing accession number and database ID. This can be passed to the retrieve method.

**series()**

Series information.

**source_title()**

The source title (e.g., Journal)

**subjects()**

The list of subject terms.

**subjects_geographic()**

The list of geographic subjects

**subjects_person()**

The list of person subjects

**title()**

The title.

**volume()**

Volume

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