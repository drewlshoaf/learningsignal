class CreateInterventionOutcomes < ActiveRecord::Migration[8.1]
  def change
    add_column :intervention_actions, :required, :boolean, default: true, null: false
    add_column :intervention_actions, :completion_status, :string, default: "pending", null: false
    add_check_constraint :intervention_actions,
      "completion_status IN ('pending', 'completed')",
      name: "intervention_actions_completion_status"

    create_table :intervention_outcomes do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :intervention_plan, null: false, foreign_key: true, index: { unique: true }
      t.references :recorded_by, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "in_progress"
      t.string :effectiveness
      t.decimal :follow_up_mastery_score, precision: 5, scale: 2
      t.text :teacher_assessment
      t.boolean :student_completed, null: false, default: false
      t.text :notes
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_check_constraint :intervention_outcomes,
      "status IN ('in_progress', 'completed')",
      name: "intervention_outcomes_status"
    add_check_constraint :intervention_outcomes,
      "effectiveness IS NULL OR effectiveness IN ('effective', 'ineffective')",
      name: "intervention_outcomes_effectiveness"
    add_check_constraint :intervention_outcomes,
      "follow_up_mastery_score IS NULL OR (follow_up_mastery_score >= 0 AND follow_up_mastery_score <= 100)",
      name: "intervention_outcomes_mastery_score"
    add_index :intervention_outcomes, %i[organization_id status]
  end
end
