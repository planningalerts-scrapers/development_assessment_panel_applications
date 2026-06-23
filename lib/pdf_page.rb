require "scraperwiki"
require "tempfile"
require "tmpdir"

# PDF Page
# Based on https://github.com/planningalerts-scrapers/ruby_pdf_helper
class PdfPage
  # all page heading text is to the right of this
  LEFT_OF_PAGE_HEADINGS = 175

  PAGE_NO_REGEXP = /\APage \d+ of \d+\z/

  # Nokogiri document
  attr_reader :page, :report_page_headings

  # Accepts binary contents of a pdf
  def initialize(page, report_page_headings)
    @page = page
    @report_page_headings = report_page_headings
  end

  def table_data
    enum, headings = text_enum_after_headings
    result = []
    while (this_row = next_row(enum, headings))
      result << this_row
      yield this_row if block_given?
    end
    result
  end

  private

  def text_enum_after_headings
    enum = @page.search("text").to_enum
    skip_page_heading(enum)
    headings = parse_headings(enum)
    [enum, headings]
  end

  # Skips page heading
  # @return [Boolean] true if table heading found (bold text), otherwise false
  def skip_page_heading(enum)
    loop do
      entry = enum.peek
      table_heading = entry["left"].to_i < LEFT_OF_PAGE_HEADINGS && entry.at("b")&.text
      return true if table_heading

      puts "Page header: #{entry.text}" if report_page_headings && entry.text.to_s != ""
      enum.next
    end
  rescue StopIteration
    false
  end

  def text_to_h(text_node)
    {
      left: text_node["left"].to_i,
      width: text_node["width"].to_i,
      text: text_node.text.to_s.strip,
      # bold: !text_node.at("b").nil?,
      # ignore: top, height, font
    }
  end

  # Collects an array of text_h entries for a row
  # text split across multiple lines have multiple entries, one per top value
  # @return [Array<Hash>,nil] array of text_h entries for a row, or nil if no entries
  def collect_row_a(enum)
    current_left = nil
    result = []
    loop do
      entry = begin
        enum.peek
      rescue StopIteration
        break
      end
      text_h = text_to_h(entry)
      current_left ||= text_h[:left]
      break if text_h[:left] < current_left

      if text_h[:text].to_s =~ /\APage \d+ of \d+\z/
        puts "FOOTER: #{text_h[:text]}" if ENV["DEBUG"]
        break unless report_page_headings

        # Output "Current Applications as at <date>" text
        enum.next
        updated_at_entry = enum.peek
        updated_at_h = text_to_h(updated_at_entry)
        puts "NOTE: #{updated_at_h[:text]}"
        break
      end
      current_left = text_h[:left]
      result << text_h
      enum.next
    end
    result.empty? ? nil : result
  end

  # Returns a hash of column heading to merged text_h entry
  # @return[Hash<Hash>,nil] hash of column heading to merged text_h entry, or nil if no entries
  def next_row(enum, headings)
    row_a = collect_row_a(enum)
    return nil if row_a.nil?

    raise "INTERNAL ERROR: row_a is not an array! #{row_a.inspect}" unless row_a.is_a? Array

    result = {}
    row_a.each do |text_h|
      heading = find_heading(headings, text_h)
      if result[heading]
        result[heading][:text] = "#{result[heading][:text]} #{text_h[:text]}"
        result[heading][:width] = [result[heading][:width], text_h[:width]].max
      else
        result[heading] = text_h
      end
    end
    result.empty? ? nil : result
  end

  # Returns heading name
  # @param headings [Array<Hash>] list of heading text_h entries
  # @param text_h [Hash] text node as a hash
  # @return [String,nil] Heading of nil if before the first heading
  def find_heading(headings, text_h)
    raise "INTERNAL ERROR: text_h[:width] is not Numeric! #{text_h.inspect}" unless text_h[:width].is_a? Numeric

    middle = text_h[:left] + text_h[:width] / 2
    heading = headings.select { |heading| heading[:left] <= middle }.last
    heading[:text] if heading
  end

  # Returns the list of headings as merged text_h entries
  def parse_headings(enum)
    heading_row = collect_row_a(enum)
    headings = []
    heading_row.each do |text_h|
      if text_h[:left] == headings.last&.fetch(:left)
        headings.last[:text] = "#{headings.last[:text]} #{text_h[:text]}"
      else
        headings << text_h
      end
    end
    puts "Found headings: #{headings.to_yaml}" if ENV["DEBUG"]
    headings
  end
end
