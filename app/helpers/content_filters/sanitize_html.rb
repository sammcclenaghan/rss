class ContentFilters::SanitizeHtml
  ALLOWED_TAGS = %w[
    a abbr b blockquote br cite code dd del dfn dl dt em figcaption figure
    h1 h2 h3 h4 h5 h6 hr i img kbd li mark ol p pre q s samp small span
    strong sub sup table tbody td tfoot th thead time tr tt u ul var video
  ].freeze

  ALLOWED_ATTRIBUTES = %w[
    href src alt title width height datetime cite
  ].freeze

  REMOVED_ELEMENTS = %w[script style iframe object embed noscript].freeze

  def self.apply(html, **)
    return html if html.blank?

    Loofah.fragment(html).scrub!(scrubber).to_s
  end

  def self.scrubber
    Loofah::Scrubber.new do |node|
      next unless node.element?

      if REMOVED_ELEMENTS.include?(node.name)
        node.remove
      elsif ALLOWED_TAGS.include?(node.name)
        node.keys.each { |attr| node.delete(attr) unless ALLOWED_ATTRIBUTES.include?(attr) }
      else
        node.replace(node.children)
      end
    end
  end
end
