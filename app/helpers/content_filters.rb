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
end
