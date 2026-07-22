require "rails_helper"

RSpec.describe Curriculum::PdfExtractor do
  let(:successful_status) { instance_double(Process::Status, success?: true) }

  it "extracts normalized text while preserving page numbers" do
    output = "  Page one has enough curriculum text for useful retrieval and review.  \n\n\nMore detail.\fPage two also contains sufficient instructional guidance for the teacher.\f"
    allow(Open3).to receive(:capture3).and_return([ output, "", successful_status ])

    pages = described_class.new("/tmp/curriculum.pdf").pages

    expect(pages.map(&:number)).to eq([ 1, 2 ])
    expect(pages.first.text).to eq("Page one has enough curriculum text for useful retrieval and review.\n\nMore detail.")
    expect(Open3).to have_received(:capture3).with("pdftotext", "-layout", "/tmp/curriculum.pdf", "-")
  end

  it "rejects image-only PDFs without usable text" do
    allow(Open3).to receive(:capture3).and_return([ "\f", "", successful_status ])

    expect { described_class.new("/tmp/scanned.pdf").pages }
      .to raise_error(described_class::ExtractionError, /OCR support is not enabled/)
  end

  it "returns a bounded extraction error from Poppler" do
    failed_status = instance_double(Process::Status, success?: false)
    allow(Open3).to receive(:capture3).and_return([ "", "Syntax Error: damaged PDF", failed_status ])

    expect { described_class.new("/tmp/damaged.pdf").pages }
      .to raise_error(described_class::ExtractionError, /damaged PDF/)
  end
end
