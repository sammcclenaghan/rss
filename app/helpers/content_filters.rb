module ContentFilters
  class Pipeline
    def initialize(*filters)
      @filters = filters
    end

    def apply(html, **options)
      @filters.reduce(html) { |result, filter| filter.apply(result, **options) }
    end
  end

  PostDescription = Pipeline.new(
    ContentFilters::TextSummary
  )

  # Full article HTML for the reader view: resolve relative URLs against the
  # article's own URL (pass base_url:), then strip everything unsafe.
  # Sanitizing last keeps the security filter as the final gate.
  ArticleContent = Pipeline.new(
    ContentFilters::FixRelativeUrls,
    ContentFilters::SanitizeHtml
  )
end
