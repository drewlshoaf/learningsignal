require "open3"

module Curriculum
  class PdfExtractor
    Page = Data.define(:number, :text)
    MINIMUM_TEXT_LENGTH = 40

    class ExtractionError < StandardError; end

    def initialize(path)
      @path = Pathname(path)
    end

    def pages
      stdout, stderr, status = Open3.capture3("pdftotext", "-layout", path.to_s, "-")
      raise ExtractionError, extraction_failure(stderr) unless status.success?

      raw_pages = stdout.split("\f", -1)
      raw_pages.pop if raw_pages.last&.strip == ""
      extracted_pages = raw_pages.each_with_index.map do |text, index|
        Page.new(number: index + 1, text: normalize(text))
      end

      if extracted_pages.sum { |page| page.text.length } < MINIMUM_TEXT_LENGTH
        raise ExtractionError, "No usable text was found. This PDF may be scanned; OCR support is not enabled yet."
      end

      extracted_pages
    rescue Errno::ENOENT
      raise ExtractionError, "PDF extraction is unavailable because pdftotext is not installed."
    end

    private

    attr_reader :path

    def normalize(text)
      text.gsub(/\r\n?/, "\n")
        .lines
        .map(&:rstrip)
        .join("\n")
        .gsub(/\n{3,}/, "\n\n")
        .strip
    end

    def extraction_failure(stderr)
      detail = stderr.to_s.strip
      detail.present? ? "PDF extraction failed: #{detail.truncate(300)}" : "PDF extraction failed."
    end
  end
end
