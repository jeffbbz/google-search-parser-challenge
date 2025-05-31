<img src="https://github.com/user-attachments/assets/b982a17e-4897-4d14-ab15-b3a2dae974de" width="300" alt="Vincent Van Gogh">

# Extract Van Gogh Paintings Code Challenge

## Overview

This project is a code challenge to extract information about Van Gogh paintings and other similar searches from Google Search Result Pages (SRP). It uses Ruby and the Nokogiri gem to parse the HTML and converting the extracted data into JSON.

## Components

### Parser (`lib/parser.rb`)
The `GoogleSearch::Parser` class is responsible for:
- Parsing Google SRP HTML files.
- Extracting details such as names, years, links, and images from result cards.
- Handling errors gracefully during parsing.

### Processor (`lib/main.rb`)
The `HtmlToJsonFileProcessor` class:
- Processes HTML files located in the `files` directory.
- Converts parsed data into JSON format.
- Saves the output to the `output` directory.

## How to Run

1. Install required gems via bundler:
```bash
   bundle install
```
2. Run the script:
```bash
  ruby lib/main.rb
```
3. Check the `output` directory for the generated JSON files.

## Requirements

- Ruby 3.2.2 or higher.
- Gems:
  - `nokogiri` gem for HTML parsing.
  - `rake` for task management/test running
  - `rspec` for testing

## Testing

Tests were written with RSpec. To run the tests:

1. Ensure all dependencies are installed (If not previously done):
```bash
   bundle install
```
2. Run the test suite using Rake:
```bash
   rake test
```
3. Or with RSpec directly:
```bash
   rspec
```

<a href="https://www.flaticon.com/free-icons/vincent-van-gogh" title="vincent van gogh icons">Van gogh icon created by Freepik - Flaticon</a>
