# frozen_string_literal: true

require 'nokogiri'
require 'rspec'
require_relative 'spec_helper'
require_relative '../lib/parser'

SAMPLE_OUTPUT = {
  "sample title": [
    {
      name: 'Sample Item 1',
      extensions: ['1889'],
      link: 'https://www.google.com/link1',
      image: 'data:image/jpeg;base64,/9j/SampleOne'
    },
    {
      name: 'Sample Item 2',
      link: 'https://www.google.com/link2',
      image: 'data:image/jpeg;base64,/9j/SampleTwo'
    },
    {
      name: 'Sample Item 3',
      extensions: ['1993'],
      link: 'https://www.google.com/link3',
      image: 'data:image/jpeg;base64,/9j/SampleThree'
    },
    {
      name: 'Sample Item 4',
      link: 'https://www.google.com/link4',
      image: 'data:image/jpeg;base64,/9j/SampleFour'
    }
  ]
}.freeze

RSpec.describe GoogleSearch::Parser do
  let(:parser) { described_class.new }
  let(:sample_html_file) { File.join(__dir__, 'fixtures', 'test_sample.html') }
  let(:van_gogh_html_file) { File.join(__dir__, '..', 'files', 'van-gogh-paintings.html') }
  let(:abdullah_html_file) { File.join(__dir__, '..', 'files', 'abdullah-ibrahim-albums.html') }
  let(:chris_ware_html_file) { File.join(__dir__, '..', 'files', 'chris-ware-books.html') }

  describe '#parse_html_file' do
    it 'parses the HTML file and returns the parsed data' do
      result = parser.parse_html_file(sample_html_file)
      expect(result).to eq(SAMPLE_OUTPUT)
    end

    it 'handles non-existent file gracefully' do
      non_existent_file_path = 'spec/fixtures/non_existent.html'
      result = parser.parse_html_file(non_existent_file_path)
      expect(result).to eq({})
    end

    it 'returns a hash with the correct title as key' do
      result = parser.parse_html_file(sample_html_file)
      expect(result).to be_a(Hash)
      expect(result).to have_key(:'sample title')
    end
  end

  describe '#find_srp_card_container_title' do
    it 'finds the container title for the sample HTML file' do
      parser.parse_html_file(sample_html_file)
      expect(parser.send(:find_srp_card_container_title)).to eq('sample title')
    end

    it 'finds the container title for the Van Gogh HTML file' do
      parser.parse_html_file(van_gogh_html_file)
      expect(parser.send(:find_srp_card_container_title)).to eq('artworks')
    end

    it 'finds the container title for the Abdullah Ibrahim HTML file' do
      parser.parse_html_file(abdullah_html_file)
      expect(parser.send(:find_srp_card_container_title)).to eq('albums')
    end
  end

  describe '#find_srp_cards_anchors' do
    it 'finds the SRP card anchors from the HTML' do
      parser.parse_html_file(sample_html_file)
      anchors = parser.send(:find_srp_cards_anchors)
      expect(anchors.size).to eq(4)
      expect(anchors.map { |anchor| anchor['href'] }).to eq(['/link1', '/link2', '/link3', '/link4'])
    end
  end

  describe '#parse_card_name' do
    it 'parses the card name from the anchor of the HTML sample' do
      parser.parse_html_file(sample_html_file)
      anchors = parser.send(:find_srp_cards_anchors)
      name = parser.send(:parse_card_name, anchors.first)
      expect(name).to eq('Sample Item 1')
    end

    it 'parses the card name from the anchor of the Van Gogh HTML' do
      parser.parse_html_file(van_gogh_html_file)
      anchors = parser.send(:find_srp_cards_anchors)
      name = parser.send(:parse_card_name, anchors.first)
      expect(name).to eq('The Starry Night')
    end

    it 'parses the card name from the anchor of the Chris Ware HTML' do
      parser.parse_html_file(chris_ware_html_file)
      anchors = parser.send(:find_srp_cards_anchors)
      name = parser.send(:parse_card_name, anchors.first)
      expect(name).to eq('Jimmy Corrigan: The Smartest Kid on Earth')
    end

    it 'handles missing alt attributes gracefully' do
      card = Nokogiri::HTML('<a><img></a>')
      name = parser.send(:parse_card_name, card)
      expect(name).to be_nil
    end
  end

  describe '#parse_card_url' do
    it 'parses the card URL from the anchor' do
      parser.parse_html_file(sample_html_file)
      anchors = parser.send(:find_srp_cards_anchors)
      url = parser.send(:parse_card_url, anchors.first)
      expect(url).to eq('https://www.google.com/link1')
    end

    it 'processes links as valid URLs on sample HTML' do
      parser.parse_html_file(sample_html_file)
      anchors = parser.send(:find_srp_cards_anchors)
      url = parser.send(:parse_card_url, anchors.first)
      expect(url).to start_with('https://www.google.com/')
    end

    it 'processes links as valid URLs on Van Gogh HTML' do
      parser.parse_html_file(van_gogh_html_file)
      anchors = parser.send(:find_srp_cards_anchors)
      url = parser.send(:parse_card_url, anchors.first)
      expect(url).to start_with('https://www.google.com/')
    end

    it 'processes links as valid URLs on Abdullah Ibrahim HTML' do
      parser.parse_html_file(abdullah_html_file)
      anchors = parser.send(:find_srp_cards_anchors)
      url = parser.send(:parse_card_url, anchors.first)
      expect(url).to start_with('https://www.google.com/')
    end
  end

  describe '#build_img_data_hash_from_script' do
    it 'builds the image data hash from script tags' do
      parser.parse_html_file(sample_html_file)
      images = parser.instance_variable_get(:@images)
      expect(images).to eq({
                             'image_id_one' => 'data:image/jpeg;base64,/9j/SampleOne',
                             'image_id_two' => 'data:image/jpeg;base64,/9j/SampleTwo',
                             'image_id_three' => 'data:image/jpeg;base64,/9j/SampleThree',
                             'image_id_four' => 'data:image/jpeg;base64,/9j/SampleFour'
                           })
    end

    it 'builds the image data hash from Van Gogh HTML script tags' do
      parser.parse_html_file(van_gogh_html_file)
      images = parser.instance_variable_get(:@images)
      expect(images).not_to be_empty
      expect(images.values.first).to start_with('data:image/jpeg;base64,')
    end

    it 'handles missing script tags gracefully' do
      parser.parse_html_file('spec/fixtures/non_existent.html')
      images = parser.instance_variable_get(:@images)
      expect(images).to eq({})
    end
  end
end
