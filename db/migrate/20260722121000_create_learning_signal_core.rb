class CreateLearningSignalCore < ActiveRecord::Migration[8.1]
  def change
    enable_extension "vector"

    create_table :organizations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :data_retention_days, null: false, default: 365
      t.timestamps
    end
    add_index :organizations, :slug, unique: true

    create_table :schools do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
    end
    add_index :schools, [ :organization_id, :slug ], unique: true

    create_table :users do |t|
      t.string :name, null: false
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.datetime :last_login_at
      t.timestamps
    end
    add_index :users, "lower(email_address)", unique: true, name: "index_users_on_lower_email"

    create_table :memberships do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :school, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "teacher"
      t.timestamps
    end
    add_index :memberships, [ :organization_id, :school_id, :user_id ], unique: true

    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end

    create_table :courses do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :school, null: false, foreign_key: true
      t.string :name, null: false
      t.string :code, null: false
      t.string :subject, null: false
      t.string :grade_level, null: false
      t.timestamps
    end
    add_index :courses, [ :organization_id, :code ], unique: true

    create_table :sections do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :school, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :academic_term, null: false
      t.timestamps
    end

    create_table :students do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :school, null: false, foreign_key: true
      t.string :external_ref, null: false
      t.string :first_name, null: false
      t.string :last_initial, null: false
      t.boolean :synthetic, null: false, default: true
      t.timestamps
    end
    add_index :students, [ :organization_id, :external_ref ], unique: true

    create_table :enrollments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :section, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :enrollments, [ :section_id, :student_id ], unique: true

    create_table :learning_objectives do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.string :code, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.timestamps
    end
    add_index :learning_objectives, [ :organization_id, :code ], unique: true

    create_table :mastery_snapshots do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.references :learning_objective, null: false, foreign_key: true
      t.decimal :score, precision: 5, scale: 2, null: false
      t.date :observed_on, null: false
      t.string :source, null: false
      t.timestamps
    end
    add_index :mastery_snapshots, [ :student_id, :learning_objective_id, :observed_on ], name: "index_mastery_timeline"

    create_table :student_signals do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :school, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.references :section, null: false, foreign_key: true
      t.references :learning_objective, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :priority, null: false, default: "medium"
      t.string :status, null: false, default: "open"
      t.string :title, null: false
      t.text :explanation, null: false
      t.jsonb :evidence_data, null: false, default: {}
      t.string :fingerprint, null: false
      t.datetime :detected_at, null: false
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :student_signals, [ :organization_id, :fingerprint ], unique: true
    add_index :student_signals, [ :section_id, :status, :priority ]

    create_table :curriculum_documents do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.string :title, null: false
      t.string :source_label, null: false
      t.string :status, null: false, default: "ready"
      t.timestamps
    end

    create_table :document_chunks do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :curriculum_document, null: false, foreign_key: true
      t.references :learning_objective, foreign_key: true
      t.text :content, null: false
      t.string :locator, null: false
      t.integer :token_count, null: false, default: 0
      t.vector :embedding, limit: 1536
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :document_chunks, [ :organization_id, :learning_objective_id ]

    create_table :investigations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :school, null: false, foreign_key: true
      t.references :student_signal, null: false, foreign_key: true
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "queued"
      t.string :current_step, null: false, default: "queued"
      t.text :failure_message
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end

    create_table :agent_runs do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :investigation, null: false, foreign_key: true
      t.string :agent_name, null: false
      t.string :status, null: false, default: "running"
      t.string :provider, null: false
      t.string :model, null: false
      t.string :prompt_version, null: false
      t.jsonb :input_data, null: false, default: {}
      t.jsonb :output_data, null: false, default: {}
      t.integer :input_tokens, null: false, default: 0
      t.integer :output_tokens, null: false, default: 0
      t.integer :latency_ms, null: false, default: 0
      t.string :provider_request_id
      t.text :error_message
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.timestamps
    end

    create_table :retrieved_evidences do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :investigation, null: false, foreign_key: true
      t.string :citation_id, null: false
      t.string :evidence_type, null: false
      t.string :source_type, null: false
      t.bigint :source_id, null: false
      t.text :excerpt, null: false
      t.string :locator, null: false
      t.decimal :relevance_score, precision: 5, scale: 4, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :retrieved_evidences, [ :investigation_id, :citation_id ], unique: true

    create_table :investigation_observations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :investigation, null: false, foreign_key: true
      t.text :statement, null: false
      t.string :confidence, null: false
      t.text :limitations
      t.timestamps
    end

    create_table :observation_evidences do |t|
      t.references :investigation_observation, null: false, foreign_key: true, index: { name: "index_observation_evidences_on_observation" }
      t.references :retrieved_evidence, null: false, foreign_key: true, index: { name: "index_observation_evidences_on_evidence" }
      t.timestamps
    end
    add_index :observation_evidences, [ :investigation_observation_id, :retrieved_evidence_id ], unique: true, name: "index_observation_evidences_unique"

    create_table :intervention_plans do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :investigation, null: false, foreign_key: true
      t.string :status, null: false, default: "draft"
      t.text :summary, null: false
      t.text :teacher_notes
      t.jsonb :original_snapshot, null: false, default: {}
      t.datetime :approved_at
      t.datetime :rejected_at
      t.timestamps
    end

    create_table :intervention_actions do |t|
      t.references :intervention_plan, null: false, foreign_key: true
      t.references :learning_objective, foreign_key: true
      t.integer :position, null: false
      t.string :title, null: false
      t.text :instructions, null: false
      t.string :duration, null: false
      t.text :success_criteria, null: false
      t.timestamps
    end
    add_index :intervention_actions, [ :intervention_plan_id, :position ], unique: true

    create_table :teacher_decisions do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :intervention_plan, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :decision, null: false
      t.text :reason
      t.jsonb :plan_snapshot, null: false, default: {}
      t.timestamps
    end

    create_table :audit_events do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :school, foreign_key: true
      t.references :user, foreign_key: true
      t.references :auditable, polymorphic: true, null: false
      t.string :action, null: false
      t.jsonb :changes_data, null: false, default: {}
      t.string :previous_hash
      t.string :event_hash, null: false
      t.string :request_id
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :audit_events, [ :organization_id, :occurred_at ]
    add_index :audit_events, :event_hash, unique: true
  end
end
