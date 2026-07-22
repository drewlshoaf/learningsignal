class StudentPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      super.joins(enrollments: :section).where(sections: { teacher_id: user.id }).distinct
    end
  end
end
