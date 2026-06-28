module PostsHelper
  def format_post_description(post)
    ContentFilters::PostDescription.apply(post.description, base_url: post.url)
  end
end
