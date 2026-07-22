class CurriculumIngestionJob < ApplicationJob
  queue_as :ingestion

  def perform(curriculum_document_id)
    document = CurriculumDocument.find(curriculum_document_id)
    return if document.status == "ready"

    Curriculum::IngestDocument.new(document:).call
  end
end
