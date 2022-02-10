# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  def allow_strict_loading
    sl = @strict_loading
    @strict_loading = false
    yield self
  ensure
    @strict_loading = sl
  end
end
