class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :organization, :school

  resets { Time.zone = nil }
end
