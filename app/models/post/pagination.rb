class Post
  module Pagination
    extend ActiveSupport::Concern

    included do
      scope :page, ->(number, per_page) {
        number = [ number.to_i, 1 ].max
        latest_first.limit(per_page).offset((number - 1) * per_page)
      }
    end
  end
end
