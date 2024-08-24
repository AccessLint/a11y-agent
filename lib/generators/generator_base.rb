# frozen_string_literal: true

class GeneratorBase < Sublayer::Generators::Base
  def update(attribute:, new_value:)
    instance_variable_set("@#{attribute}", new_value)
  end
end
