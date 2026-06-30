# frozen_string_literal: true

module RestrictedHTTP
  # The outcome of an HTTP GET: the status, the (size-limited) body, and the
  # response content type. Returned by every RestrictedHTTP client.
  Response = Data.define(:status, :body, :content_type) do
    def ok?
      status.between?(200, 299)
    end
  end
end
