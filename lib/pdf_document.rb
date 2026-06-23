require "scraperwiki"
require "tempfile"
require "tmpdir"

# PDF Document
# Based on https://github.com/planningalerts-scrapers/ruby_pdf_helper
class PdfDocument
  # Nokogiri document
  attr_reader :doc

  # Accepts binary contents of a pdf
  def initialize(data)
    # Write data to a temporary file (with a pdf extension)
    src = Tempfile.new(%w[pdftohtml_src. .pdf])
    dst = Tempfile.new(%w[pdftohtml_dst. .xml])

    src.binmode
    dst.binmode

    src.write(data.b)
    src.close

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Run in a temp dir so the extracted images are discarded
        command = "pdftohtml -xml -enc UTF-8 -noframes #{src.path} #{dst.path}"
        puts "Running pdftohtml to convert pdf to xml pages..."
        # Outputs page numbers read ...
        system(command)
      end
    end

    xml_content = dst.read
    # Cleanup
    src.unlink
    dst.unlink

    raise "pdftohtml produced no output" if xml_content.empty?

    puts "Parsing XML document ..."
    @doc = Nokogiri::XML(xml_content)
  end

  # Returns pages
  def pages
    @doc.search("page")
  end
end
