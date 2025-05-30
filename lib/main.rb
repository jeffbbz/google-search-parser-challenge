# frozen_string_literal: true

require 'json'
require_relative 'parser'

class HtmlToJsonFileProcessor
  def initialize
    @parser = GoogleSearch::Parser.new
  end

  def process_html_to_json
    load_html_files.each do |file|
      parsed = @parser.parse_html_file(file)
      output_to_json(file, parsed)
    end
  end

  private

  def load_html_files
    Dir.glob(File.join(__dir__, '..', 'files', '*.html'))
  end

  def output_to_json(file, parsed)
    output_directory = File.join(__dir__, '..', 'output')
    Dir.mkdir(output_directory) unless Dir.exist?(output_directory)

    output_file_name = "#{File.basename(file, '.html')}.json"
    output_file = File.join(output_directory, output_file_name)

    File.write(output_file, JSON.pretty_generate(parsed))
  end
end

HtmlToJsonFileProcessor.new.process_html_to_json
