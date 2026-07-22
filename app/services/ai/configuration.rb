module Ai
  class Configuration
    class << self
      def settings
        Rails.application.config_for(:ai).with_indifferent_access
      end

      def provider = settings.fetch(:provider)
      def model = settings.fetch(:model)
      def embedding_model = settings.fetch(:embedding_model)
      def reasoning_effort = settings.fetch(:reasoning_effort)
      def request_timeout = settings.fetch(:request_timeout).to_i
    end
  end
end
