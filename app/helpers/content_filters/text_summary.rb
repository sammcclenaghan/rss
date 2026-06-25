require "cgi"

class ContentFilters::TextSummary
  # Feedbin-style summary cleaning: parse as HTML, prune unsafe elements and
  # their contents (not just tags), then extract plain text.
  DASHED_ELEMENT_PARENTS = %w[svg math].freeze
  SUMMARY_PRUNE_ELEMENTS = %w[pre].freeze
  LEAKED_CSS_BLOCK = /[^{}]{1,240}\{[^{}]*\}/m
  LEAKED_CSS_PREFIX = /\A\s*[.#a-zA-Z][^{}]*\{[^{}]*\}/m

  def self.apply(html, length: nil, **)
    return "" if html.blank?

    text = text_from_html(CGI.unescapeHTML(html.to_s))
    text = strip_leaked_css(text).gsub(/\s+/, " ").strip
    length ? truncate(text, length) : text
  end

  def self.text_from_html(html)
    document = Loofah.html5_fragment(html)
    document.scrub!(custom_elements).scrub!(summary_elements).scrub!(:prune)
    document.to_text(encode_special_chars: false)
  rescue
    ActionController::Base.helpers.strip_tags(html)
  end

  def self.custom_elements
    Loofah::Scrubber.new do |node|
      next unless node.element?

      if DASHED_ELEMENT_PARENTS.include?(node.name)
        Loofah::Scrubber::STOP
      elsif node.name.include?("-")
        node.name = "span"
      end
    end
  end

  def self.summary_elements
    Loofah::Scrubber.new do |node|
      next unless node.element?

      node.remove if SUMMARY_PRUNE_ELEMENTS.include?(node.name)
    end
  end

  def self.strip_leaked_css(text)
    return text unless text.match?(LEAKED_CSS_PREFIX)

    text.gsub(LEAKED_CSS_BLOCK, "")
  end

  def self.truncate(text, length)
    text.length > length ? "#{text[0, length]}..." : text
  end
end
