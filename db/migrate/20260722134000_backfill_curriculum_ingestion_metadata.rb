class BackfillCurriculumIngestionMetadata < ActiveRecord::Migration[8.1]
  def up
    add_column :curriculum_documents, :file_checksum, :string
    add_column :document_chunks, :content_checksum, :string

    execute <<~SQL.squish
      UPDATE curriculum_documents
      SET chunk_count = chunk_totals.chunk_count
      FROM (
        SELECT curriculum_document_id, COUNT(*) AS chunk_count
        FROM document_chunks
        GROUP BY curriculum_document_id
      ) AS chunk_totals
      WHERE curriculum_documents.id = chunk_totals.curriculum_document_id
    SQL

    execute <<~SQL.squish
      UPDATE curriculum_documents
      SET learning_objective_id = objective_totals.learning_objective_id
      FROM (
        SELECT curriculum_document_id, MIN(learning_objective_id) AS learning_objective_id
        FROM document_chunks
        WHERE learning_objective_id IS NOT NULL
        GROUP BY curriculum_document_id
        HAVING COUNT(DISTINCT learning_objective_id) = 1
      ) AS objective_totals
      WHERE curriculum_documents.id = objective_totals.curriculum_document_id
        AND curriculum_documents.learning_objective_id IS NULL
    SQL

    execute <<~SQL.squish
      UPDATE document_chunks
      SET content_checksum = encode(sha256(convert_to(content, 'UTF8')), 'hex')
    SQL

    execute <<~SQL.squish
      UPDATE curriculum_documents
      SET file_checksum = active_storage_blobs.checksum
      FROM active_storage_attachments
      INNER JOIN active_storage_blobs ON active_storage_blobs.id = active_storage_attachments.blob_id
      WHERE active_storage_attachments.record_type = 'CurriculumDocument'
        AND active_storage_attachments.name = 'file'
        AND active_storage_attachments.record_id = curriculum_documents.id
    SQL

    change_column_null :document_chunks, :content_checksum, false
    add_index :curriculum_documents,
      [ :organization_id, :file_checksum ],
      unique: true,
      where: "file_checksum IS NOT NULL",
      name: "index_curriculum_documents_on_tenant_checksum"
    add_index :document_chunks, :content_checksum
  end

  def down
    remove_index :document_chunks, :content_checksum
    remove_index :curriculum_documents, name: "index_curriculum_documents_on_tenant_checksum"
    remove_column :document_chunks, :content_checksum
    remove_column :curriculum_documents, :file_checksum
  end
end
