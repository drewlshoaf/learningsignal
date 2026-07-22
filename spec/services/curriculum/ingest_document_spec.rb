require "rails_helper"

RSpec.describe Curriculum::IngestDocument do
  def uploaded_document(scenario)
    CurriculumDocument.new(
      organization: scenario.fetch(:organization),
      course: scenario.fetch(:course),
      learning_objective: scenario.fetch(:objective),
      uploaded_by: scenario.fetch(:teacher),
      title: "Uploaded curriculum",
      source_label: "Teacher upload",
      status: "pending"
    ).tap do |document|
      document.file.attach(io: StringIO.new("%PDF-1.4 test"), filename: "curriculum.pdf", content_type: "application/pdf")
      document.save!
    end
  end

  it "replaces chunks with page-grounded embeddings and records completion" do
    scenario = build_learning_scenario
    document = uploaded_document(scenario)
    extractor = Class.new do
      def initialize(_path); end

      def pages
        [
          Curriculum::PdfExtractor::Page.new(number: 1, text: "Slope is vertical change divided by horizontal change in a linear relationship."),
          Curriculum::PdfExtractor::Page.new(number: 2, text: "Ask students to explain the rate of change using a graph, table, and equation.")
        ]
      end
    end

    described_class.new(
      document:,
      provider: Ai::Providers::DeterministicProvider.new,
      extractor_class: extractor
    ).call

    expect(document.reload).to have_attributes(status: "ready", page_count: 2, chunk_count: 2, failure_message: nil)
    expect(document.document_chunks.pluck(:locator)).to eq([ "Page 1 · chunk 1", "Page 2 · chunk 1" ])
    expect(document.document_chunks).to all(have_attributes(learning_objective: scenario.fetch(:objective)))
    expect(document.document_chunks.first.embedding.to_a.length).to eq(1536)
    expect(document.document_chunks.first.content_checksum).to match(/\A[0-9a-f]{64}\z/)
    expect(scenario.fetch(:organization).audit_events.last.action).to eq("curriculum_document.processed")
  end

  it "marks the document failed when extraction cannot produce text" do
    scenario = build_learning_scenario
    document = uploaded_document(scenario)
    extractor = Class.new do
      def initialize(_path); end

      def pages
        raise Curriculum::PdfExtractor::ExtractionError, "Scanned PDF"
      end
    end

    expect do
      described_class.new(
        document:,
        provider: Ai::Providers::DeterministicProvider.new,
        extractor_class: extractor
      ).call
    end.to raise_error(Curriculum::PdfExtractor::ExtractionError, "Scanned PDF")

    expect(document.reload).to have_attributes(status: "failed", failure_message: "Scanned PDF")
    expect(scenario.fetch(:organization).audit_events.last.action).to eq("curriculum_document.failed")
  end
end
