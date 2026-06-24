class ContentFilters::FixRelativeUrls
  URL_ATTRIBUTES = {
    "img" => %w[src],
    "video" => %w[src poster],
    "source" => %w[src],
    "a" => %w[href],
  }.freeze

  def self.apply(html, base_url: nil)
    return html if html.blank? || base_url.blank?

    doc = Nokogiri::HTML5.fragment(html)
    base = directory_of(base_url)

    URL_ATTRIBUTES.each do |tag, attrs|
      attrs.each do |attr|
        doc.css("#{tag}[#{attr}]").each do |el|
          el[attr] = resolve(el[attr], base)
        end
      end
    end

    doc.to_html
  end

  def self.resolve(url, base)
    return url if url.blank? || url.start_with?("data:", "mailto:", "#")

    uri = URI.parse(url)
    return url if uri.absolute?

    URI.join(base, uri).to_s
  rescue URI::InvalidURIError
    url
  end

  def self.directory_of(url)
    uri = URI.parse(url)
    uri.path = uri.path.sub(/\/[^\/]*$/, "/") if uri.path.present? && !uri.path.end_with?("/")
    uri.to_s
  end
end
