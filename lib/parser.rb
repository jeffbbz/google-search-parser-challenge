# frozen_string_literal: true

require 'nokogiri'

module GoogleSearch
  class Parser
    BOOK_ALBUM_DETAIL_SELECTOR = 'wp-grid-tile > div:not(:has(img))'
    # This class is responsible for parsing Google SRP HTML files to scrape info from the result card grid/carousel.
    def initialize
      @doc = nil
      @cards = nil
      @card_container_title = nil
      @images = {}
    end

    def parse_html_file(file)
      @doc = Nokogiri::HTML(File.open(file))
      build_img_data_hash_from_script
      @card_container_title = find_srp_card_container_title
      @cards = find_srp_cards_anchors
      { "#{@card_container_title}": parse_srp_cards }
    rescue StandardError => e
      puts "Error parsing file: #{e.message}"
      {}
    end

    private

    def find_srp_card_container_title
      title_span = @doc.at_css('div[aria-level="2"][role="heading"] > span')
      title_span&.text&.strip
    rescue StandardError => e
      puts "Error finding SRP card container title: #{e.message}"
      nil
    end

    def find_srp_cards_anchors
      # Van Gogh Paintings: Find 1st anchor child of divs with style and an anchor child with an img child
      artwork_cards_anchors = 'div:has(> a > img)[style] > a:first'

      # Other Results: Find 1st anchor child of the 1st child div of divs with role=presentation
      books_albums_cards_anchors = 'div[role="presentation"] > div:first-child > a:first'

      # Combine with OR/comma separator
      @doc.css("#{artwork_cards_anchors}, #{books_albums_cards_anchors}")
    rescue StandardError => e
      puts "Error finding SRP cards anchors: #{e.message}"
      []
    end

    def parse_srp_cards
      @cards.map do |card|
        card_data = { name: parse_card_name(card) }
        year = parse_card_year(card)
        card_data[:extensions] = [year] unless year.nil?
        card_data[:link] = parse_card_url(card)
        card_data[:image] = parse_card_img_src(card)
        card_data
      end.compact
    rescue StandardError => e
      puts "Error parsing SRP card: #{e.message}"
      {}
    end

    def parse_card_name(card)
      if card_has_img_with_alt?(card)
        card.at_css('img').attr('alt').strip
      else
        # Find the name from the 1st div child of the div child that doesn't have an img child
        card.at_css("#{BOOK_ALBUM_DETAIL_SELECTOR} > div:first-child").text.strip
      end
    rescue StandardError => e
      puts "Error finding SRP card name: #{e.message}"
      nil
    end

    def parse_card_year(card)
      if card_has_img_with_alt?(card)
        card.css('div > div').find { |div| div.text.strip.match?(/^\d{4}$/) }&.text&.strip
      else
        # Find the year from the last div child of the div child that doesn't have an img child
        year = card.at_css("#{BOOK_ALBUM_DETAIL_SELECTOR} > div:last")&.text&.strip
        year unless year.to_s.strip.empty?
      end
    rescue StandardError => e
      puts "Error finding SRP card year: #{e.message}"
      nil
    end

    def card_has_img_with_alt?(card)
      card.at_css('img[alt][alt!=""]')
    end

    def parse_card_url(card)
      url = "https://www.google.com#{card['href']}"
      # remove client parameter and trailing & if exists
      url.include?('client=') ? url.gsub(/(client=[^&]+&?|&$)/, '') : url
    rescue StandardError => e
      puts "Error finding SRP card URL: #{e.message}"
      nil
    end

    def parse_card_img_src(card)
      img = if card.at_css('wp-grid-tile')
              card.at_css('wp-grid-tile > div > img')
            else
              card.at_css('img')
            end

      @images[img['id']] || img['data-src']
    rescue StandardError => e
      puts "Error finding SRP card img src: #{e.message}"
      nil
    end

    def build_img_data_hash_from_script
      # Define the XPath query as a variable for clarity
      script_xpath = <<~XPATH
          //script[
          contains(., "s=") or
          contains(., "s =") or
          contains(., "ii=") or
          contains(., "ii =")
        ]
      XPATH

      @doc.xpath(script_xpath).each do |script|
        script_text = script.text
        encoded_src = script_text[/var\s+s\s*=\s*'([^']+)'/, 1]
        img_id = script_text[/var\s+ii\s*=\s*\[\s*'([^']+)'/, 1]

        next unless encoded_src && img_id

        full_decoded_src = "\"#{encoded_src}\"".undump
        @images[img_id] = full_decoded_src
      end
    rescue StandardError => e
      puts "Error parsing image data from script: #{e.message}"
      {}
    end
  end
end
