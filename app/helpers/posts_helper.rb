module PostsHelper
  WORDS_PER_MINUTE = 200

  def format_post_description(post)
    ContentFilters::PostDescription.apply(post.description, base_url: post.url)
  end

  # Estimated reading time in minutes from the captured word count, or nil when
  # there is no captured content to measure.
  def reading_time(post)
    words = post.content&.word_count.to_i
    return if words.zero?

    [ (words.to_f / WORDS_PER_MINUTE).ceil, 1 ].max
  end
end
