class CreateEvaluationRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :evaluation_runs do |t|
      t.string :suite, null: false
      t.string :status, null: false, default: "running"
      t.string :provider, null: false
      t.string :model, null: false
      t.string :prompt_version, null: false
      t.string :prompt_digest, null: false
      t.string :cases_digest, null: false
      t.string :git_sha, null: false
      t.jsonb :thresholds, null: false, default: {}
      t.jsonb :metrics, null: false, default: {}
      t.jsonb :gate_failures, null: false, default: []
      t.integer :input_tokens, null: false, default: 0
      t.integer :output_tokens, null: false, default: 0
      t.decimal :estimated_cost_usd, precision: 12, scale: 6, null: false, default: 0
      t.integer :latency_ms, null: false, default: 0
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.text :error_message
      t.timestamps
    end

    create_table :evaluation_results do |t|
      t.references :evaluation_run, null: false, foreign_key: true
      t.string :case_id, null: false
      t.integer :case_version, null: false
      t.string :case_type, null: false
      t.string :status, null: false
      t.jsonb :tags, null: false, default: []
      t.jsonb :metrics, null: false, default: {}
      t.jsonb :details, null: false, default: {}
      t.integer :input_tokens, null: false, default: 0
      t.integer :output_tokens, null: false, default: 0
      t.decimal :estimated_cost_usd, precision: 12, scale: 6, null: false, default: 0
      t.integer :latency_ms, null: false, default: 0
      t.text :error_message
      t.timestamps
    end

    add_index :evaluation_runs, %i[suite created_at]
    add_index :evaluation_runs, :status
    add_index :evaluation_results, %i[evaluation_run_id case_id], unique: true
    add_check_constraint :evaluation_runs, "status IN ('running', 'passed', 'failed', 'errored')", name: "evaluation_runs_status_check"
    add_check_constraint :evaluation_results, "status IN ('passed', 'failed', 'errored')", name: "evaluation_results_status_check"
    add_check_constraint :evaluation_results, "case_type IN ('investigation', 'retrieval')", name: "evaluation_results_case_type_check"
  end
end
