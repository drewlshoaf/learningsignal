class CreateAssessmentRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :assessments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.string :external_ref, null: false
      t.string :title, null: false
      t.string :assessment_type, null: false
      t.decimal :maximum_score, precision: 7, scale: 2, null: false, default: 0
      t.string :status, null: false, default: "published"
      t.boolean :synthetic, null: false, default: true
      t.timestamps
    end
    add_index :assessments, %i[organization_id external_ref], unique: true

    create_table :assessment_questions do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :assessment, null: false, foreign_key: true
      t.references :learning_objective, null: false, foreign_key: true
      t.string :external_ref, null: false
      t.string :prompt_reference, null: false
      t.string :question_type, null: false
      t.decimal :maximum_points, precision: 7, scale: 2, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :assessment_questions, %i[assessment_id external_ref], unique: true
    add_index :assessment_questions, %i[organization_id learning_objective_id], name: "index_assessment_questions_on_tenant_objective"

    create_table :assessment_attempts do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.references :assessment, null: false, foreign_key: true
      t.references :section, null: false, foreign_key: true
      t.string :external_ref, null: false
      t.integer :attempt_number, null: false
      t.decimal :score, precision: 7, scale: 2, null: false, default: 0
      t.decimal :maximum_score, precision: 7, scale: 2, null: false, default: 0
      t.decimal :percentage, precision: 5, scale: 2, null: false, default: 0
      t.datetime :started_at
      t.datetime :submitted_at
      t.string :status, null: false, default: "submitted"
      t.boolean :synthetic, null: false, default: true
      t.timestamps
    end
    add_index :assessment_attempts, %i[organization_id section_id external_ref], unique: true, name: "index_assessment_attempts_on_tenant_section_external_ref"
    add_index :assessment_attempts, %i[assessment_id student_id section_id attempt_number], unique: true, name: "index_assessment_attempts_on_identity"
    add_index :assessment_attempts, %i[student_id submitted_at]

    create_table :question_responses do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :assessment_attempt, null: false, foreign_key: true
      t.references :assessment_question, null: false, foreign_key: true
      t.text :response_text
      t.string :selected_answer
      t.boolean :correct, null: false, default: false
      t.decimal :points_earned, precision: 7, scale: 2, null: false, default: 0
      t.text :feedback
      t.datetime :submitted_at
      t.timestamps
    end
    add_index :question_responses, %i[assessment_attempt_id assessment_question_id], unique: true, name: "index_question_responses_on_attempt_question"
    add_index :question_responses, %i[organization_id submitted_at]
  end
end
