module WebFinger
  # Base error class for all WebFinger errors
  class Error < StandardError; end

  # Raised when fetching a WebFinger resource fails (HTTP errors, timeouts)
  class FetchError < Error; end

  # Raised when parsing a JRD response fails (malformed JSON, missing fields)
  class ParseError < Error; end

  # Raised when the requested resource is not found (404)
  class ResourceNotFound < Error; end
end
