# frozen_string_literal: true

class StarredPost < ApplicationRecord
  belongs_to :post
end
