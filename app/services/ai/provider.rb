module Ai
  class Provider
    def generate(model:, input:, schema:, instructions:, metadata: {})
      raise NotImplementedError
    end

    def embed(model:, inputs:)
      raise NotImplementedError
    end

    def name
      raise NotImplementedError
    end
  end
end
