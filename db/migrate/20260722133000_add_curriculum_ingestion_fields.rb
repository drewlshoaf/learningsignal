class AddCurriculumIngestionFields < ActiveRecord::Migration[8.1]
  def change
    add_reference :curriculum_documents, :learning_objective, foreign_key: true
    add_reference :curriculum_documents, :uploaded_by, foreign_key: { to_table: :users }
    add_column :curriculum_documents, :page_count, :integer, null: false, default: 0
    add_column :curriculum_documents, :chunk_count, :integer, null: false, default: 0
    add_column :curriculum_documents, :failure_message, :text
    add_column :curriculum_documents, :processing_started_at, :datetime
    add_column :curriculum_documents, :processed_at, :datetime
  end
end
