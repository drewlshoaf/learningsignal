class CreateStudentDataImports < ActiveRecord::Migration[8.1]
  def change
    create_table :student_data_imports do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :school, null: false, foreign_key: true
      t.references :section, null: false, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }
      t.string :import_type, null: false
      t.string :status, null: false, default: "pending"
      t.string :source_filename, null: false
      t.string :file_checksum, null: false
      t.integer :total_rows, null: false, default: 0
      t.integer :valid_rows, null: false, default: 0
      t.integer :error_count, null: false, default: 0
      t.jsonb :preview_rows, null: false, default: []
      t.jsonb :validation_errors, null: false, default: []
      t.jsonb :applied_summary, null: false, default: {}
      t.text :failure_message
      t.datetime :completed_at
      t.timestamps
    end

    add_index :student_data_imports,
      [ :organization_id, :section_id, :import_type, :file_checksum ],
      unique: true,
      name: "index_student_data_imports_on_source_identity"
    add_index :student_data_imports, [ :organization_id, :created_at ]
  end
end
