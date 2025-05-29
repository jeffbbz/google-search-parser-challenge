# frozen_string_literal: true

require 'nokogiri'

module GoogleSearch
  class Parser
    attr_reader :doc

    def initialize
      @doc = nil
    end

    def parse_html_file(file)
      @doc = Nokogiri::HTML(File.open(file))
      result = find_srp_cards
      result.map(&:to_html)
    rescue StandardError => e
      puts "Error parsing file: #{e.message}"
      {}
    end

    private

    def find_srp_cards
      # Condition for Van Gogh Paintings: Find div elements with an anchor child that itself has img child
      # The div must have a style attribute and it should != display:none
      artwork_cards = 'div:has(> a > img)[style]:not([style*="display:none"])'

      # Condition for Other Results: Find div elements with role=presentation attribute and style != display:none
      # Then find the first child div of those divs
      books_albums_cards = 'div[role="presentation"]:not([style="display:none"]) > div:first-child'

      # Combine with OR (comma separator)
      @doc.css("#{artwork_cards}, #{books_albums_cards}")
    end
  end
end
