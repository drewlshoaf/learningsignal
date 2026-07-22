require "digest"

module Audit
  class Record
    def self.call(...) = new(...).call

    def initialize(organization:, auditable:, action:, user: nil, school: nil, changes: {}, request_id: nil)
      @organization = organization
      @auditable = auditable
      @action = action
      @user = user
      @school = school
      @changes = changes
      @request_id = request_id
    end

    def call
      organization.with_lock do
        previous_hash = organization.audit_events.order(:occurred_at, :id).last&.event_hash
        occurred_at = Time.current
        payload = {
          organization_id: organization.id,
          auditable_type: auditable.class.name,
          auditable_id: auditable.id,
          action: action,
          user_id: user&.id,
          changes: changes,
          previous_hash: previous_hash,
          occurred_at: occurred_at.iso8601(6)
        }

        AuditEvent.create!(
          organization: organization,
          school: school,
          user: user,
          auditable: auditable,
          action: action,
          changes_data: changes,
          previous_hash: previous_hash,
          event_hash: Digest::SHA256.hexdigest(JSON.generate(payload.deep_stringify_keys.sort.to_h)),
          request_id: request_id,
          occurred_at: occurred_at
        )
      end
    end

    private

    attr_reader :organization, :auditable, :action, :user, :school, :changes, :request_id
  end
end
