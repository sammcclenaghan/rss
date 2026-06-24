class Post
  # Deletes posts older than a retention window, along with their thumbnails.
  class Pruner
    BATCH_SIZE = 250

    # Deletes posts older than retention_days. Returns the number deleted.
    def prune(retention_days)
      cutoff = Time.current.to_i - (retention_days.to_i * 1.day.to_i)

      deleted = 0
      Post.published_before(cutoff).in_batches(of: BATCH_SIZE) do |batch|
        delete_thumbnails(batch)
        deleted += batch.delete_all
      end
      deleted
    end

    private
      def delete_thumbnails(posts)
        posts.where.not(thumbnail: "").pluck(:thumbnail).each do |path|
          file = Rails.root.join("public/storage", path)
          file.delete if file.exist?
        end
      end
  end
end
