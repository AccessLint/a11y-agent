# frozen_string_literal: true

require_relative './generator_base'

class CodeReplacementGenerator < GeneratorBase
  llm_output_adapter type: :single_string,
                     name: 'hydrate_web_document_with_fake_variables',
                     description: 'Given a web document template, generate a new file with fake data interpolated into the template.'

  def initialize(contents:, extension: nil)
    super()
    @contents = contents
    @extension = extension
  end

  def generate
    super
  end

  def prompt
    <<~PROMPT
      Given the following #{@extension} template contents, generate a new file by
      replacing any undefined variables with fake data. Only replace undefined variables,
      do not generate new markup.

      #{@extension} code:
      #{@contents}

      Return the contents with the fake data interpolated.
    PROMPT
  end
end
