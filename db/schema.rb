# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_22_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agent_runs", force: :cascade do |t|
    t.string "agent_name", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.datetime "finished_at"
    t.jsonb "input_data", default: {}, null: false
    t.integer "input_tokens", default: 0, null: false
    t.bigint "investigation_id", null: false
    t.integer "latency_ms", default: 0, null: false
    t.string "model", null: false
    t.bigint "organization_id", null: false
    t.jsonb "output_data", default: {}, null: false
    t.integer "output_tokens", default: 0, null: false
    t.string "prompt_version", null: false
    t.string "provider", null: false
    t.string "provider_request_id"
    t.datetime "started_at", null: false
    t.string "status", default: "running", null: false
    t.datetime "updated_at", null: false
    t.index ["investigation_id"], name: "index_agent_runs_on_investigation_id"
    t.index ["organization_id"], name: "index_agent_runs_on_organization_id"
  end

  create_table "assessment_attempts", force: :cascade do |t|
    t.bigint "assessment_id", null: false
    t.integer "attempt_number", null: false
    t.datetime "created_at", null: false
    t.string "external_ref", null: false
    t.decimal "maximum_score", precision: 7, scale: 2, default: "0.0", null: false
    t.bigint "organization_id", null: false
    t.decimal "percentage", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "score", precision: 7, scale: 2, default: "0.0", null: false
    t.bigint "section_id", null: false
    t.datetime "started_at"
    t.string "status", default: "submitted", null: false
    t.bigint "student_id", null: false
    t.datetime "submitted_at"
    t.boolean "synthetic", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id", "student_id", "section_id", "attempt_number"], name: "index_assessment_attempts_on_identity", unique: true
    t.index ["assessment_id"], name: "index_assessment_attempts_on_assessment_id"
    t.index ["organization_id", "section_id", "external_ref"], name: "index_assessment_attempts_on_tenant_section_external_ref", unique: true
    t.index ["organization_id"], name: "index_assessment_attempts_on_organization_id"
    t.index ["section_id"], name: "index_assessment_attempts_on_section_id"
    t.index ["student_id", "submitted_at"], name: "index_assessment_attempts_on_student_id_and_submitted_at"
    t.index ["student_id"], name: "index_assessment_attempts_on_student_id"
  end

  create_table "assessment_questions", force: :cascade do |t|
    t.bigint "assessment_id", null: false
    t.datetime "created_at", null: false
    t.string "external_ref", null: false
    t.bigint "learning_objective_id", null: false
    t.decimal "maximum_points", precision: 7, scale: 2, null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "organization_id", null: false
    t.string "prompt_reference", null: false
    t.string "question_type", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id", "external_ref"], name: "index_assessment_questions_on_assessment_id_and_external_ref", unique: true
    t.index ["assessment_id"], name: "index_assessment_questions_on_assessment_id"
    t.index ["learning_objective_id"], name: "index_assessment_questions_on_learning_objective_id"
    t.index ["organization_id", "learning_objective_id"], name: "index_assessment_questions_on_tenant_objective"
    t.index ["organization_id"], name: "index_assessment_questions_on_organization_id"
  end

  create_table "assessments", force: :cascade do |t|
    t.string "assessment_type", null: false
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.string "external_ref", null: false
    t.decimal "maximum_score", precision: 7, scale: 2, default: "0.0", null: false
    t.bigint "organization_id", null: false
    t.string "status", default: "published", null: false
    t.boolean "synthetic", default: true, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_assessments_on_course_id"
    t.index ["organization_id", "external_ref"], name: "index_assessments_on_organization_id_and_external_ref", unique: true
    t.index ["organization_id"], name: "index_assessments_on_organization_id"
  end

  create_table "audit_events", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "auditable_id", null: false
    t.string "auditable_type", null: false
    t.jsonb "changes_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "event_hash", null: false
    t.datetime "occurred_at", null: false
    t.bigint "organization_id", null: false
    t.string "previous_hash"
    t.string "request_id"
    t.bigint "school_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_events_on_auditable"
    t.index ["event_hash"], name: "index_audit_events_on_event_hash", unique: true
    t.index ["organization_id", "occurred_at"], name: "index_audit_events_on_organization_id_and_occurred_at"
    t.index ["organization_id"], name: "index_audit_events_on_organization_id"
    t.index ["school_id"], name: "index_audit_events_on_school_id"
    t.index ["user_id"], name: "index_audit_events_on_user_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "grade_level", null: false
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.bigint "school_id", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "code"], name: "index_courses_on_organization_id_and_code", unique: true
    t.index ["organization_id"], name: "index_courses_on_organization_id"
    t.index ["school_id"], name: "index_courses_on_school_id"
  end

  create_table "curriculum_documents", force: :cascade do |t|
    t.integer "chunk_count", default: 0, null: false
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.text "failure_message"
    t.string "file_checksum"
    t.bigint "learning_objective_id"
    t.bigint "organization_id", null: false
    t.integer "page_count", default: 0, null: false
    t.datetime "processed_at"
    t.datetime "processing_started_at"
    t.string "source_label", null: false
    t.string "status", default: "ready", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_id"
    t.index ["course_id"], name: "index_curriculum_documents_on_course_id"
    t.index ["learning_objective_id"], name: "index_curriculum_documents_on_learning_objective_id"
    t.index ["organization_id", "file_checksum"], name: "index_curriculum_documents_on_tenant_checksum", unique: true, where: "(file_checksum IS NOT NULL)"
    t.index ["organization_id"], name: "index_curriculum_documents_on_organization_id"
    t.index ["uploaded_by_id"], name: "index_curriculum_documents_on_uploaded_by_id"
  end

  create_table "document_chunks", force: :cascade do |t|
    t.text "content", null: false
    t.string "content_checksum", null: false
    t.datetime "created_at", null: false
    t.bigint "curriculum_document_id", null: false
    t.vector "embedding", limit: 1536
    t.bigint "learning_objective_id"
    t.string "locator", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "organization_id", null: false
    t.integer "token_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["content_checksum"], name: "index_document_chunks_on_content_checksum"
    t.index ["curriculum_document_id"], name: "index_document_chunks_on_curriculum_document_id"
    t.index ["learning_objective_id"], name: "index_document_chunks_on_learning_objective_id"
    t.index ["organization_id", "learning_objective_id"], name: "idx_on_organization_id_learning_objective_id_9102f153fe"
    t.index ["organization_id"], name: "index_document_chunks_on_organization_id"
  end

  create_table "enrollments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.bigint "section_id", null: false
    t.string "status", default: "active", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_enrollments_on_organization_id"
    t.index ["section_id", "student_id"], name: "index_enrollments_on_section_id_and_student_id", unique: true
    t.index ["section_id"], name: "index_enrollments_on_section_id"
    t.index ["student_id"], name: "index_enrollments_on_student_id"
  end

  create_table "intervention_actions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "duration", null: false
    t.text "instructions", null: false
    t.bigint "intervention_plan_id", null: false
    t.bigint "learning_objective_id"
    t.integer "position", null: false
    t.text "success_criteria", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["intervention_plan_id", "position"], name: "idx_on_intervention_plan_id_position_6783f419cf", unique: true
    t.index ["intervention_plan_id"], name: "index_intervention_actions_on_intervention_plan_id"
    t.index ["learning_objective_id"], name: "index_intervention_actions_on_learning_objective_id"
  end

  create_table "intervention_plans", force: :cascade do |t|
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.bigint "investigation_id", null: false
    t.bigint "organization_id", null: false
    t.jsonb "original_snapshot", default: {}, null: false
    t.datetime "rejected_at"
    t.string "status", default: "draft", null: false
    t.text "summary", null: false
    t.text "teacher_notes"
    t.datetime "updated_at", null: false
    t.index ["investigation_id"], name: "index_intervention_plans_on_investigation_id"
    t.index ["organization_id"], name: "index_intervention_plans_on_organization_id"
  end

  create_table "investigation_observations", force: :cascade do |t|
    t.string "confidence", null: false
    t.datetime "created_at", null: false
    t.bigint "investigation_id", null: false
    t.text "limitations"
    t.bigint "organization_id", null: false
    t.text "statement", null: false
    t.datetime "updated_at", null: false
    t.index ["investigation_id"], name: "index_investigation_observations_on_investigation_id"
    t.index ["organization_id"], name: "index_investigation_observations_on_organization_id"
  end

  create_table "investigations", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "current_step", default: "queued", null: false
    t.text "failure_message"
    t.bigint "organization_id", null: false
    t.bigint "school_id", null: false
    t.datetime "started_at"
    t.string "status", default: "queued", null: false
    t.bigint "student_signal_id", null: false
    t.bigint "teacher_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_investigations_on_organization_id"
    t.index ["school_id"], name: "index_investigations_on_school_id"
    t.index ["student_signal_id"], name: "index_investigations_on_student_signal_id"
    t.index ["teacher_id"], name: "index_investigations_on_teacher_id"
  end

  create_table "learning_objectives", force: :cascade do |t|
    t.string "code", null: false
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.bigint "organization_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_learning_objectives_on_course_id"
    t.index ["organization_id", "code"], name: "index_learning_objectives_on_organization_id_and_code", unique: true
    t.index ["organization_id"], name: "index_learning_objectives_on_organization_id"
  end

  create_table "mastery_snapshots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "learning_objective_id", null: false
    t.date "observed_on", null: false
    t.bigint "organization_id", null: false
    t.decimal "score", precision: 5, scale: 2, null: false
    t.bigint "section_id", null: false
    t.string "source", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["learning_objective_id"], name: "index_mastery_snapshots_on_learning_objective_id"
    t.index ["organization_id", "section_id", "student_id", "learning_objective_id", "observed_on", "source"], name: "index_mastery_snapshots_on_import_identity", unique: true
    t.index ["organization_id"], name: "index_mastery_snapshots_on_organization_id"
    t.index ["section_id"], name: "index_mastery_snapshots_on_section_id"
    t.index ["student_id", "learning_objective_id", "observed_on"], name: "index_mastery_timeline"
    t.index ["student_id"], name: "index_mastery_snapshots_on_student_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.string "role", default: "teacher", null: false
    t.bigint "school_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["organization_id", "school_id", "user_id"], name: "index_memberships_on_organization_id_and_school_id_and_user_id", unique: true
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["school_id"], name: "index_memberships_on_school_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "observation_evidences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "investigation_observation_id", null: false
    t.bigint "retrieved_evidence_id", null: false
    t.datetime "updated_at", null: false
    t.index ["investigation_observation_id", "retrieved_evidence_id"], name: "index_observation_evidences_unique", unique: true
    t.index ["investigation_observation_id"], name: "index_observation_evidences_on_observation"
    t.index ["retrieved_evidence_id"], name: "index_observation_evidences_on_evidence"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "data_retention_days", default: 365, null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "question_responses", force: :cascade do |t|
    t.bigint "assessment_attempt_id", null: false
    t.bigint "assessment_question_id", null: false
    t.boolean "correct", default: false, null: false
    t.datetime "created_at", null: false
    t.text "feedback"
    t.bigint "organization_id", null: false
    t.decimal "points_earned", precision: 7, scale: 2, default: "0.0", null: false
    t.text "response_text"
    t.string "selected_answer"
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.index ["assessment_attempt_id", "assessment_question_id"], name: "index_question_responses_on_attempt_question", unique: true
    t.index ["assessment_attempt_id"], name: "index_question_responses_on_assessment_attempt_id"
    t.index ["assessment_question_id"], name: "index_question_responses_on_assessment_question_id"
    t.index ["organization_id", "submitted_at"], name: "index_question_responses_on_organization_id_and_submitted_at"
    t.index ["organization_id"], name: "index_question_responses_on_organization_id"
  end

  create_table "retrieved_evidences", force: :cascade do |t|
    t.string "citation_id", null: false
    t.datetime "created_at", null: false
    t.string "evidence_type", null: false
    t.text "excerpt", null: false
    t.bigint "investigation_id", null: false
    t.string "locator", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "organization_id", null: false
    t.decimal "relevance_score", precision: 5, scale: 4, default: "0.0", null: false
    t.bigint "source_id", null: false
    t.string "source_type", null: false
    t.datetime "updated_at", null: false
    t.index ["investigation_id", "citation_id"], name: "index_retrieved_evidences_on_investigation_id_and_citation_id", unique: true
    t.index ["investigation_id"], name: "index_retrieved_evidences_on_investigation_id"
    t.index ["organization_id"], name: "index_retrieved_evidences_on_organization_id"
  end

  create_table "schools", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "slug"], name: "index_schools_on_organization_id_and_slug", unique: true
    t.index ["organization_id"], name: "index_schools_on_organization_id"
  end

  create_table "sections", force: :cascade do |t|
    t.string "academic_term", null: false
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.bigint "school_id", null: false
    t.bigint "teacher_id", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_sections_on_course_id"
    t.index ["organization_id"], name: "index_sections_on_organization_id"
    t.index ["school_id"], name: "index_sections_on_school_id"
    t.index ["teacher_id"], name: "index_sections_on_teacher_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "student_data_imports", force: :cascade do |t|
    t.jsonb "applied_summary", default: {}, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "error_count", default: 0, null: false
    t.text "failure_message"
    t.string "file_checksum", null: false
    t.string "import_type", null: false
    t.bigint "organization_id", null: false
    t.jsonb "preview_rows", default: [], null: false
    t.bigint "school_id", null: false
    t.bigint "section_id", null: false
    t.string "source_filename", null: false
    t.string "status", default: "pending", null: false
    t.integer "total_rows", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_id", null: false
    t.integer "valid_rows", default: 0, null: false
    t.jsonb "validation_errors", default: [], null: false
    t.index ["organization_id", "created_at"], name: "index_student_data_imports_on_organization_id_and_created_at"
    t.index ["organization_id", "section_id", "import_type", "file_checksum"], name: "index_student_data_imports_on_source_identity", unique: true
    t.index ["organization_id"], name: "index_student_data_imports_on_organization_id"
    t.index ["school_id"], name: "index_student_data_imports_on_school_id"
    t.index ["section_id"], name: "index_student_data_imports_on_section_id"
    t.index ["uploaded_by_id"], name: "index_student_data_imports_on_uploaded_by_id"
  end

  create_table "student_signals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "detected_at", null: false
    t.jsonb "evidence_data", default: {}, null: false
    t.text "explanation", null: false
    t.string "fingerprint", null: false
    t.string "kind", null: false
    t.bigint "learning_objective_id", null: false
    t.bigint "organization_id", null: false
    t.string "priority", default: "medium", null: false
    t.datetime "resolved_at"
    t.bigint "school_id", null: false
    t.bigint "section_id", null: false
    t.string "status", default: "open", null: false
    t.bigint "student_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["learning_objective_id"], name: "index_student_signals_on_learning_objective_id"
    t.index ["organization_id", "fingerprint"], name: "index_student_signals_on_organization_id_and_fingerprint", unique: true
    t.index ["organization_id"], name: "index_student_signals_on_organization_id"
    t.index ["school_id"], name: "index_student_signals_on_school_id"
    t.index ["section_id", "status", "priority"], name: "index_student_signals_on_section_id_and_status_and_priority"
    t.index ["section_id"], name: "index_student_signals_on_section_id"
    t.index ["student_id"], name: "index_student_signals_on_student_id"
  end

  create_table "students", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_ref", null: false
    t.string "first_name", null: false
    t.string "last_initial", null: false
    t.bigint "organization_id", null: false
    t.bigint "school_id", null: false
    t.boolean "synthetic", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "external_ref"], name: "index_students_on_organization_id_and_external_ref", unique: true
    t.index ["organization_id"], name: "index_students_on_organization_id"
    t.index ["school_id"], name: "index_students_on_school_id"
  end

  create_table "teacher_decisions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "decision", null: false
    t.bigint "intervention_plan_id", null: false
    t.bigint "organization_id", null: false
    t.jsonb "plan_snapshot", default: {}, null: false
    t.text "reason"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["intervention_plan_id"], name: "index_teacher_decisions_on_intervention_plan_id"
    t.index ["organization_id"], name: "index_teacher_decisions_on_organization_id"
    t.index ["user_id"], name: "index_teacher_decisions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.datetime "last_login_at"
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email_address)::text)", name: "index_users_on_lower_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agent_runs", "investigations"
  add_foreign_key "agent_runs", "organizations"
  add_foreign_key "assessment_attempts", "assessments"
  add_foreign_key "assessment_attempts", "organizations"
  add_foreign_key "assessment_attempts", "sections"
  add_foreign_key "assessment_attempts", "students"
  add_foreign_key "assessment_questions", "assessments"
  add_foreign_key "assessment_questions", "learning_objectives"
  add_foreign_key "assessment_questions", "organizations"
  add_foreign_key "assessments", "courses"
  add_foreign_key "assessments", "organizations"
  add_foreign_key "audit_events", "organizations"
  add_foreign_key "audit_events", "schools"
  add_foreign_key "audit_events", "users"
  add_foreign_key "courses", "organizations"
  add_foreign_key "courses", "schools"
  add_foreign_key "curriculum_documents", "courses"
  add_foreign_key "curriculum_documents", "learning_objectives"
  add_foreign_key "curriculum_documents", "organizations"
  add_foreign_key "curriculum_documents", "users", column: "uploaded_by_id"
  add_foreign_key "document_chunks", "curriculum_documents"
  add_foreign_key "document_chunks", "learning_objectives"
  add_foreign_key "document_chunks", "organizations"
  add_foreign_key "enrollments", "organizations"
  add_foreign_key "enrollments", "sections"
  add_foreign_key "enrollments", "students"
  add_foreign_key "intervention_actions", "intervention_plans"
  add_foreign_key "intervention_actions", "learning_objectives"
  add_foreign_key "intervention_plans", "investigations"
  add_foreign_key "intervention_plans", "organizations"
  add_foreign_key "investigation_observations", "investigations"
  add_foreign_key "investigation_observations", "organizations"
  add_foreign_key "investigations", "organizations"
  add_foreign_key "investigations", "schools"
  add_foreign_key "investigations", "student_signals"
  add_foreign_key "investigations", "users", column: "teacher_id"
  add_foreign_key "learning_objectives", "courses"
  add_foreign_key "learning_objectives", "organizations"
  add_foreign_key "mastery_snapshots", "learning_objectives"
  add_foreign_key "mastery_snapshots", "organizations"
  add_foreign_key "mastery_snapshots", "sections"
  add_foreign_key "mastery_snapshots", "students"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "schools"
  add_foreign_key "memberships", "users"
  add_foreign_key "observation_evidences", "investigation_observations"
  add_foreign_key "observation_evidences", "retrieved_evidences"
  add_foreign_key "question_responses", "assessment_attempts"
  add_foreign_key "question_responses", "assessment_questions"
  add_foreign_key "question_responses", "organizations"
  add_foreign_key "retrieved_evidences", "investigations"
  add_foreign_key "retrieved_evidences", "organizations"
  add_foreign_key "schools", "organizations"
  add_foreign_key "sections", "courses"
  add_foreign_key "sections", "organizations"
  add_foreign_key "sections", "schools"
  add_foreign_key "sections", "users", column: "teacher_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "student_data_imports", "organizations"
  add_foreign_key "student_data_imports", "schools"
  add_foreign_key "student_data_imports", "sections"
  add_foreign_key "student_data_imports", "users", column: "uploaded_by_id"
  add_foreign_key "student_signals", "learning_objectives"
  add_foreign_key "student_signals", "organizations"
  add_foreign_key "student_signals", "schools"
  add_foreign_key "student_signals", "sections"
  add_foreign_key "student_signals", "students"
  add_foreign_key "students", "organizations"
  add_foreign_key "students", "schools"
  add_foreign_key "teacher_decisions", "intervention_plans"
  add_foreign_key "teacher_decisions", "organizations"
  add_foreign_key "teacher_decisions", "users"
end
