# frozen_string_literal: true

class BaseAction < Sublayer::Actions::Base
  def call
    raise NotImplementedError
  end
end
