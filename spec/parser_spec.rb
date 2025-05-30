# frozen_string_literal: true

require 'fileutils'
require 'nokogiri'
require 'rspec'
require_relative '../lib/parser'

SAMPLE_OUTPUT = {
  "Sample Title": [
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
}

RSpec.describe GoogleSearch::Parser do
  let(:parser) { described_class.new }
  let(:html_file_path) { 'spec/fixtures/sample.html' }

  describe '#parse_html_file' do
    it 'parses the HTML file and returns the parsed data' do
      result = parser.parse_html_file(html_file_path)
      expect(result).to eq(SAMPLE_OUTPUT)
    end
  end

  describe '#find_srp_card_container_title' do
    it 'finds the container title from the HTML' do
      parser.parse_html_file(html_file_path)
      expect(parser.send(:find_srp_card_container_title)).to eq('Sample Title')
    end
  end

  describe '#find_srp_cards_anchors' do
    it 'finds the SRP card anchors from the HTML' do
      parser.parse_html_file(html_file_path)
      anchors = parser.send(:find_srp_cards_anchors)
      expect(anchors.size).to eq(4)
      expect(anchors.map { |anchor| anchor['href'] }).to eq(['/link1', '/link2', '/link3', '/link4'])
    end
  end

  describe '#parse_card_name' do
    it 'parses the card name from the anchor' do
      parser.parse_html_file(html_file_path)
      anchors = parser.send(:find_srp_cards_anchors)
      name = parser.send(:parse_card_name, anchors.first)
      expect(name).to eq('Sample Item 1')
    end
  end

  describe '#parse_card_url' do
    it 'parses the card URL from the anchor' do
      parser.parse_html_file(html_file_path)
      anchors = parser.send(:find_srp_cards_anchors)
      url = parser.send(:parse_card_url, anchors.first)
      expect(url).to eq('https://www.google.com/link1')
    end
  end

  describe '#build_img_data_hash_from_script' do
    it 'builds the image data hash from script tags' do
      parser.parse_html_file(html_file_path)
      images = parser.instance_variable_get(:@images)
      expect(images).to eq({
                             'image_id_one' => 'data:image/jpeg;base64,/9j/SampleOne',
                             'image_id_two' => 'data:image/jpeg;base64,/9j/SampleTwo',
                             'image_id_three' => 'data:image/jpeg;base64,/9j/SampleThree',
                             'image_id_four' => 'data:image/jpeg;base64,/9j/SampleFour'
                           })
    end
  end
end
