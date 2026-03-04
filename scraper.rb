#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"

require "open-uri"
require "yaml"

require "nokogiri"
require "scraperwiki"

require_relative "lib/pdf_document"
require_relative "lib/pdf_page"

class Scraper
  INFO_URL = "https://www.planning.wa.gov.au/development-assessment-panels/current-development-assessment-panels-applications-and-information"
  PDF_URL = "https://www.planning.wa.gov.au/docs/default-source/daps-docs-website/current-applications.pdf"

  REPORTABLE_HEADINGS = ["DAP Panel", "LG Name"].freeze

  def run
    date_scraped = Date.today.iso8601
    count = 0

    puts "Retrieving #{PDF_URL} ..."
    pdf_content = URI.open(PDF_URL).read
    puts "Parsing as a PdfDocument ..." if ENV['DEBUG']
    pdf_doc = PdfDocument.new(pdf_content)
    page_no = 0
    pdf_doc.pages.each do |page_entry|
      page_no += 1
      puts "Processing page# #{page_no}"
      pdf_page = PdfPage.new(page_entry, page_no == 1)
      pdf_page.table_data do |data|
        puts "ROW: #{data.to_yaml}" if ENV["DEBUG"]
        REPORTABLE_HEADINGS.each do |heading|
          puts "Section: #{heading}: #{data[heading]&.fetch(:text)}" if data[heading]
        end
        council_reference = data["DAP Application Reference Number"]&.fetch(:text)
        address = data["Property Location"]&.fetch(:text)
        address = "#{address}, WA" if address && !address.end_with?(" WA")
        description = data["Application Description"]&.fetch(:text)
        record = {
          "council_reference" => council_reference,
          "description" => description,
          "address" => address,
          "date_scraped" => date_scraped,
          "info_url" => INFO_URL,
          "comment_url" => INFO_URL,
        }

        date_received_text = data["Date Application Received"]&.fetch(:text)
        begin
          record[:date_received] = Date.parse(date_received_text).iso8601 if date_received_text.to_s != ""
        rescue StandardError => e
          puts "Warning: Ignored unparsable date_received: #{date_received_text} with error: #{e}"
        end

        puts "Saving #{council_reference} - #{address}"
        ScraperWiki.save_sqlite(["council_reference"], record)
        puts "RECORD: #{record.inspect}" if ENV["DEBUG"]
        count += 1
      end
      puts "Finished processing page #{page_no}" if ENV["DEBUG"]
    end
    puts "Finished! Processed #{count} records."
  end

  #   puts "Scanning document to extract pages ..."
  #   page_no = 0
  #   doc.search('page').each do |p|
  #     page_no += 1
  #     puts "Scanning page #{page_no} for table rows ..."
  #
  #     text_rows = p.search('text')
  #     # returns columns =
  #     # Array:
  #     #   {
  #     #     left: left value (integer)
  #     #     name: "Name of column"
  #     #     width: max width of heading for diagnostic purposes
  #     # }
  #     # data_rows are the text_rows excluding the text entries that where headings and any above
  #
  #     columns, data_rows = PdfDocument.extract_headings(text_rows)
  #
  #     PdfDocument.extract_table_from_pdf_text(p.search('text'), COLUMNS).each do |row|

  #     end
  #   end
  #   puts "",
  #        "Found #{count} records."
  # end
end

# Run the scraper whilst allowing this file to be required in tests without auto-execution
Scraper.new.run if __FILE__ == $PROGRAM_NAME
