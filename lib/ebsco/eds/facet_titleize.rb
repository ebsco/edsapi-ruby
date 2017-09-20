module EBSCO
  module EDS
    class Titleize

      SMALL_WORDS = %w{a an and as at but by en for if in of on or the to v v. via vs vs.}
      ACRONYMS = %w{u.s. usa npr ieee llc g.p.o. n.y. n.c. b.v.}

      def titleize(title, opts={})
        title = title.dup
        title.downcase! unless title[/[[:lower:]]/]  # assume all-caps need fixing

        small_words = SMALL_WORDS + (opts[:small_words] || [])
        small_words = small_words + small_words.map { |small| small.capitalize }

        acronyms = ACRONYMS + (opts[:acronyms] || [])
        acronyms = acronyms + acronyms.map { |acronym| acronym.downcase }

        phrases(title).map do |phrase|
          words = phrase.split
          words.map.with_index do |word, index|

            if acronyms.include?(word.gsub(/[()]/,''))
              word.upcase
            else

              def word.capitalize
                # like String#capitalize, but it starts with the first letter
                self.sub(/[[:alpha:]].*/) {|subword| subword.capitalize}
              end

              case word
                when /[[:alpha:]]\.[[:alpha:]]/  # words with dots in, like "example.com"
                  word
                when /[-‑]/  # hyphenated word (regular and non-breaking)
                  word.split(/([-‑])/).map do |part|
                    SMALL_WORDS.include?(part) ? part : part.capitalize
                  end.join
                when /^[[:alpha:]].*[[:upper:]]/ # non-first letter capitalized already
                  word
                when /^[[:digit:]]/  # first character is a number
                  word
                when *small_words
                  if index == 0 || index == words.size - 1
                    word.capitalize
                  else
                    word.downcase
                  end
                else
                  word.capitalize
              end

            end

          end.join(' ')
        end.join(' ')
      end

      def phrases(title)
        phrases = [[]]
        title.split.each do |word|
          phrases.last << word
          phrases << [] if ends_with_punctuation?(word) && !small_word?(word)
        end
        phrases.reject(&:empty?).map { |phrase| phrase.join ' ' }
      end

      private

      def small_word?(word)
        SMALL_WORDS.include? word.downcase
      end

      def ends_with_punctuation?(word)
        word =~ /[:.;?!]$/
      end
    end

  end
end
