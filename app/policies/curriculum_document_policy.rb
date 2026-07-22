class CurriculumDocumentPolicy < ApplicationPolicy
  def index? = user.present?
  def reprocess? = update? && record.status == "failed"
end
