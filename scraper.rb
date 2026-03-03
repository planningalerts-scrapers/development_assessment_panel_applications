#!/usr/bin/env ruby
# frozen_string_literal: true

Bundler.require

require 'scraperwiki'
require "open-uri"
require 'nokogiri'
require File.dirname(__FILE__) + "/ruby_pdf_helper/scraper"

class Scraper
  INFO_URL = "https://www.planning.wa.gov.au/development-assessment-panels/current-development-assessment-panels-applications-and-information"
  PDF_URL = "http://www.planning.wa.gov.au/daps/data/Current%20DAP%20Applications/Current%20DAP%20Applications.pdf"

  def run
    date_scraped = Date.today.iso8601
    count = 0

    doc = Nokogiri::XML(PdfHelper.pdftoxml(open(PDF_URL) { |f| f.read }))

    doc.search('page').each do |p|
      PdfHelper.extract_table_from_pdf_text(p.search('text')).each do |row|
        unless row[0] == 'No'
          council_reference = row[0]
          address = row[4].split("\n").last + ", WA"
          description = row[4] ? row[4].gsub("\n", "") : nil
          record = {
            "council_reference" => council_reference,
            "description" => description,
            "address" => address,
            "date_scraped" => date_scraped,
            "info_url" => INFO_URL,
            "comment_url" => INFO_URL,
          }
          begin
            record["date_received"] = Date.strptime(row[5].gsub("//", "/").strip, "%d/%m/%Y").to_s if row[5]
          rescue => e
            puts "Warning: #{row[5]} had #{e} (ignored)"
          end
          puts "Saving #{council_reference} - #{address}"
          ScraperWiki.save_sqlite(["council_reference"], record)
          puts "RECORD: #{record.inspect}" if ENV['DEBUG']
          count += 1
        end
      end
    end
    puts "",
         "Found #{count} records."
  end
end

# Run the scraper whilst allowing this file to be required in tests without auto-execution
Scraper.new.run if __FILE__ == $PROGRAM_NAME
