module Curriculum
  class IngestDocument
    EMBEDDING_BATCH_SIZE = 32

    def initialize(
      document:,
      provider: Ai::ProviderRegistry.fetch,
      extractor_class: PdfExtractor,
      chunker: Chunker.new
    )
      @document = document
      @provider = provider
      @extractor_class = extractor_class
      @chunker = chunker
    end

    def call
      document.update!(
        status: "processing",
        failure_message: nil,
        processing_started_at: Time.current,
        processed_at: nil
      )

      pages = document.file.open { |file| extractor_class.new(file.path).pages }
      chunks = chunker.call(pages)
      raise PdfExtractor::ExtractionError, "No curriculum chunks could be created from this PDF." if chunks.empty?

      embeddings = embed(chunks.map(&:content))
      raise Ai::ProviderError, "The embedding provider returned an unexpected number of vectors." unless embeddings.length == chunks.length

      CurriculumDocument.transaction do
        document.document_chunks.delete_all
        chunks.zip(embeddings).each do |chunk, embedding|
          document.document_chunks.create!(
            organization: document.organization,
            learning_objective: document.learning_objective,
            content: chunk.content,
            locator: chunk.locator,
            token_count: chunk.token_count,
            metadata: chunk.metadata,
            embedding: embedding
          )
        end
        document.update!(
          status: "ready",
          page_count: pages.length,
          chunk_count: chunks.length,
          processed_at: Time.current
        )
      end

      record_audit("curriculum_document.processed", page_count: pages.length, chunk_count: chunks.length)
      document
    rescue StandardError => error
      mark_failed(error)
      raise
    end

    private

    attr_reader :document, :provider, :extractor_class, :chunker

    def embed(inputs)
      inputs.each_slice(EMBEDDING_BATCH_SIZE).flat_map do |batch|
        provider.embed(model: Ai::Configuration.embedding_model, inputs: batch)
      end
    end

    def mark_failed(error)
      document.update!(
        status: "failed",
        failure_message: error.message.to_s.truncate(1_000),
        processed_at: Time.current
      )
      record_audit("curriculum_document.failed", error_class: error.class.name, message: error.message.to_s.truncate(300))
    rescue StandardError
      nil
    end

    def record_audit(action, changes)
      Audit::Record.call(
        organization: document.organization,
        school: document.course.school,
        user: document.uploaded_by,
        auditable: document,
        action:,
        changes:
      )
    end
  end
end
