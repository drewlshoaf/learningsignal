require "net/http"

module Ai
  class HttpTransport
    def initialize(base_url:, api_key:, timeout: Configuration.request_timeout)
      @base_url = base_url
      @api_key = api_key
      @timeout = timeout
    end

    def post(path, body)
      uri = URI.join(normalized_base_url, path.delete_prefix("/"))
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@api_key}" if @api_key.present?
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(body)

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: @timeout) do |http|
        http.request(request)
      end

      parsed = JSON.parse(response.body)
      return parsed if response.is_a?(Net::HTTPSuccess)

      message = parsed.dig("error", "message") || "Provider returned HTTP #{response.code}"
      raise ProviderError, message
    rescue JSON::ParserError => error
      raise ProviderError, "Provider returned invalid JSON: #{error.message}"
    rescue Timeout::Error, SocketError, SystemCallError => error
      raise ProviderError, "Provider request failed: #{error.message}"
    end

    private

    def normalized_base_url
      @base_url.end_with?("/") ? @base_url : "#{@base_url}/"
    end
  end
end
