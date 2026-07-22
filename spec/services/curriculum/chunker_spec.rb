require "rails_helper"

RSpec.describe Curriculum::Chunker do
  it "keeps chunks within page boundaries and overlaps long pages" do
    first_page_words = Array.new(300) { |index| "word#{index}" }
    pages = [
      Curriculum::PdfExtractor::Page.new(number: 1, text: first_page_words.join(" ")),
      Curriculum::PdfExtractor::Page.new(number: 2, text: "A short second page")
    ]

    chunks = described_class.new.call(pages)

    expect(chunks.map(&:locator)).to eq([ "Page 1 · chunk 1", "Page 1 · chunk 2", "Page 2 · chunk 1" ])
    expect(chunks.first.token_count).to eq(220)
    expect(chunks.second.content.split.first(40)).to eq(chunks.first.content.split.last(40))
    expect(chunks.last.metadata).to eq(page_number: 2, page_chunk_index: 1)
  end

  it "skips pages without extracted text" do
    pages = [ Curriculum::PdfExtractor::Page.new(number: 4, text: "") ]

    expect(described_class.new.call(pages)).to be_empty
  end
end
