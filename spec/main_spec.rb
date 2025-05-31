# frozen_string_literal: true

require 'rspec'
require_relative 'spec_helper'
require_relative '../lib/main'

RSpec.describe HtmlToJsonFileProcessor do
  let(:processor) { HtmlToJsonFileProcessor.new }
  let(:test_sample_dir) { File.join(__dir__, 'fixtures') }
  let(:output_dir) { File.join(__dir__, '..', 'output') }
  let(:output_json_file) { File.join(output_dir, 'test_sample.json') }
  let(:test_sample_html_file) { File.join(test_sample_dir, 'test_sample.html') }
  let(:expected_test_output_json_file) { File.join(test_sample_dir, 'expected_test_output.json') }

  describe '#load_html_files' do
    it 'loads all HTML files from files directory and only HTML files' do
      html_files = processor.send(:load_html_files)
      html_file_count = Dir.glob(File.join(__dir__, '..', 'files', '*.html')).count
      expect(html_files.size).to eq(html_file_count)
    end
  end

  describe '#process_html_to_json' do
    it 'processes all HTML files and generates corresponding JSON files' do
      allow(processor).to receive(:load_html_files).and_return([test_sample_html_file])
      processor.process_html_to_json
      expect(File.exist?(output_json_file)).to be true
      output_json_content = JSON.parse(File.read(output_json_file))
      expected_json_content = JSON.parse(File.read(expected_test_output_json_file))
      expect(output_json_content).to eq(expected_json_content)
    end

    after do
      File.delete(output_json_file) if File.exist?(output_json_file)
    end
  end

  describe '#output_to_json' do
    let(:parsed_data) { GoogleSearch::Parser.new.parse_html_file(test_sample_html_file) }

    it 'generates JSON file of correct name in output directory' do
      processor.send(:output_to_json, test_sample_html_file, parsed_data)
      expect(File.exist?(output_dir)).to be true
      expect(File.exist?(output_json_file)).to be true
    end

    it 'generates the correct JSON output for a given HTML file' do
      processor.send(:output_to_json, test_sample_html_file, parsed_data)
      output_json_content = JSON.parse(File.read(output_json_file))
      expected_json_content = JSON.parse(File.read(expected_test_output_json_file))
      expect(output_json_content).to eq(expected_json_content)
    end

    after(:each) do
      File.delete(output_json_file) if File.exist?(output_json_file)
    end
  end

  describe '#van-gogh JSON is same as expected JSON' do
    let(:van_gogh_html_file) { File.join(__dir__, '..', 'files', 'van-gogh-paintings.html') }
    let(:parsed_data) { GoogleSearch::Parser.new.parse_html_file(van_gogh_html_file) }
    let(:expected_van_gogh_json_file) { File.join(__dir__, '..', 'files', 'expected-array.json') }

    it 'checks if output/van-gogh-paintings.json matches files/expected-array.json' do
      processor.send(:output_to_json, van_gogh_html_file, parsed_data)
      van_gogh_json_file = File.join(__dir__, '..', 'output', 'van-gogh-paintings.json')

      expect(File.exist?(van_gogh_json_file)).to be true

      van_gogh_output_content = JSON.parse(File.read(van_gogh_json_file))
      expected_van_gogh_content = JSON.parse(File.read(expected_van_gogh_json_file))

      expect(van_gogh_output_content).to eq(expected_van_gogh_content)
    end
  end
end
