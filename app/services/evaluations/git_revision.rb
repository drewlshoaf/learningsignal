module Evaluations
  class GitRevision
    def self.current
      ENV["GITHUB_SHA"].presence || ENV["GIT_SHA"].presence || from_checkout || "local"
    end

    def self.from_checkout
      git_path = Rails.root.join(".git")
      return unless git_path.directory?

      head = git_path.join("HEAD").read.strip
      return head unless head.start_with?("ref: ")

      ref_path = git_path.join(head.delete_prefix("ref: "))
      ref_path.read.strip if ref_path.file?
    rescue Errno::ENOENT
      nil
    end

    private_class_method :from_checkout
  end
end
