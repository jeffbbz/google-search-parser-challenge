# frozen_string_literal: true

require 'nokogiri'

module GoogleSearch
  # This class is responsible for parsing Google SRP HTML files to scrape info from the result card grid/carousel.
  class Parser
    BOOK_ALBUM_DETAIL_SELECTOR = 'wp-grid-tile > div:not(:has(img))'
    # Van Gogh Paintings: Find 1st anchor child of divs with style and an anchor child with an img child
    ARTWORK_CARDS_ANCHORS_SELECTOR = 'div:has(> a > img)[style] > a:first'
    # Other Results: Find 1st anchor child of the 1st child div of divs with role=presentation
    BOOKS_ALBUMS_CARDS_ANCHORS_SELECTOR = 'div[role="presentation"] > div:first-child > a:first'
    CARD_CONTAINER_TITLE_SELECTOR = 'div[aria-level="2"][role="heading"] > span'

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
      handle_error("Error parsing HTML file: #{file}", e, {})
    end

    private

    def find_srp_card_container_title
      title_span = @doc.at_css(CARD_CONTAINER_TITLE_SELECTOR)
      title_span&.text&.strip&.downcase
    rescue StandardError => e
      handle_error('Error finding SRP card container title', e, nil)
    end

    def find_srp_cards_anchors
      @doc.css("#{ARTWORK_CARDS_ANCHORS_SELECTOR}, #{BOOKS_ALBUMS_CARDS_ANCHORS_SELECTOR}")
    rescue StandardError => e
      handle_error('Error finding SRP cards anchors', e, [])
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
      handle_error('Error parsing SRP cards', e, {})
    end

    def parse_card_name(card)
      if card_has_img_with_alt?(card)
        card.at_css('img').attr('alt').strip
      else
        # Find the name from the 1st div child of the div child that doesn't have an img child
        card.at_css("#{BOOK_ALBUM_DETAIL_SELECTOR} > div:first-child").text.strip
      end
    rescue StandardError => e
      handle_error('Error finding SRP card name', e)
    end

    def parse_card_year(card)
      card_has_img_with_alt?(card) ? find_year_from_img_alt(card) : find_year_from_last_div_child(card)
    rescue StandardError => e
      handle_error('Error finding SRP card year', e)
    end

    def find_year_from_img_alt(card)
      card.css('div > div').find { |div| div.text.strip.match?(/^\d{4}$/) }&.text&.strip
    end

    def find_year_from_last_div_child(card)
      # Find the year from the last div child of the div child that doesn't have an img child
      year = card.at_css("#{BOOK_ALBUM_DETAIL_SELECTOR} > div:last")&.text&.strip
      year unless year.to_s.strip.empty?
    end

    def card_has_img_with_alt?(card)
      card.at_css('img[alt][alt!=""]')
    end

    def parse_card_url(card)
      url = "https://www.google.com#{card['href']}"
      # remove client parameter and trailing & if exists
      url.include?('client=') ? url.gsub(/(client=[^&]+&?|&$)/, '') : url
    rescue StandardError => e
      handle_error('Error finding SRP card URL', e)
    end

    def parse_card_img_src(card)
      img = if card.at_css('wp-grid-tile')
              card.at_css('wp-grid-tile > div > img')
            else
              card.at_css('img')
            end

      @images[img['id']] || img['data-src']
    rescue StandardError => e
      handle_error('Error finding SRP card img src', e)
    end

    def build_img_data_hash_from_script
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
      handle_error('Error building image data hash from script', e, {})
    end

    def handle_error(message, error, return_value = nil)
      puts "#{message}: #{error.message}"
      return_value
    end
  end
end
