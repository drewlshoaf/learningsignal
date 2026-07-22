module InterventionOutcomes
  class Record
    def self.call(...) = new(...).call

    def initialize(outcome:, actor:, attributes:, completed_action_ids:, mastery_snapshot_id: nil, request_id: nil)
      @outcome = outcome
      @actor = actor
      @attributes = attributes
      @completed_action_ids = Array(completed_action_ids).compact_blank.map(&:to_i)
      @mastery_snapshot_id = mastery_snapshot_id.presence
      @request_id = request_id
    end

    def call
      created = outcome.new_record?

      InterventionOutcome.transaction do
        outcome.assign_attributes(attributes)
        outcome.organization = plan.organization
        outcome.recorded_by = actor
        outcome.recorded_at = Time.current
        outcome.follow_up_mastery_score = selected_mastery_snapshot.score if selected_mastery_snapshot
        outcome.save!

        update_action_completion!
        sync_mastery_snapshot!
        sync_signal_status!
        record_audit!(created ? "created" : "updated")
      end

      outcome
    end

    private

    attr_reader :outcome, :actor, :attributes, :completed_action_ids, :mastery_snapshot_id, :request_id

    def plan = outcome.intervention_plan

    def selected_mastery_snapshot
      return @selected_mastery_snapshot if defined?(@selected_mastery_snapshot)
      return @selected_mastery_snapshot = nil if mastery_snapshot_id.blank?

      @selected_mastery_snapshot = plan.investigation.student.mastery_snapshots.where(
        organization: plan.organization,
        section: plan.investigation.section,
        learning_objective: plan.investigation.learning_objective,
        observed_on: (plan.approved_at || plan.created_at).to_date..
      ).where.not("source LIKE ?", "Intervention outcome %").find(mastery_snapshot_id)
    end

    def update_action_completion!
      valid_ids = plan.intervention_actions.pluck(:id)
      raise ActiveRecord::RecordNotFound if (completed_action_ids - valid_ids).any?

      plan.intervention_actions.each do |action|
        action.update!(completion_status: completed_action_ids.include?(action.id) ? "completed" : "pending")
      end
    end

    def sync_mastery_snapshot!
      source = "Intervention outcome #{outcome.id}"
      relation = plan.investigation.student.mastery_snapshots.where(
        organization: plan.organization,
        section: plan.investigation.section,
        learning_objective: plan.investigation.learning_objective,
        source: source
      )

      if outcome.completed? && selected_mastery_snapshot.nil?
        snapshot = relation.first_or_initialize
        snapshot.assign_attributes(observed_on: outcome.recorded_at.to_date, score: outcome.follow_up_mastery_score)
        snapshot.save!
      else
        relation.destroy_all
      end
    end

    def sync_signal_status!
      plan.investigation.student_signal.update!(status: outcome.completed? ? "resolved" : "open")
    end

    def record_audit!(event)
      Audit::Record.call(
        organization: plan.organization,
        school: plan.investigation.school,
        user: actor,
        auditable: outcome,
        action: "intervention_outcome.#{event}",
        changes: {
          snapshot: outcome.snapshot,
          completed_action_ids: completed_action_ids,
          selected_mastery_snapshot_id: selected_mastery_snapshot&.id
        },
        request_id: request_id
      )
    end
  end
end
