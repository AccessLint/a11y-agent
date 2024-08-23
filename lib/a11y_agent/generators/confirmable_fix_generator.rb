# frozen_string_literal: true

require 'dotenv/load'
require 'sublayer'

class ConfirmableFixGenerator < Sublayer::Generators::Base
  llm_output_adapter type: :named_strings,
                     name: 'lint_fix',
                     description: 'A fix for lint failures',
                     item_name: 'lint_fix',
                     attributes: [
                       {
                         name: 'description',
                         description: 'A brief description of the fix and why it is important'
                       },
                       {
                         name: 'impact',
                         description: 'A brief explanation of how the fix impacts assistive technologies'
                       },
                       {
                         name: 'fixed',
                         description: 'The complete source code with the fix applied'
                       }
                     ]

  def initialize(lint_failure:, source_code:, additional_instructions: nil)
    super()
    @source_code = source_code
    @lint_failure = lint_failure
    @additional_instructions = additional_instructions
    @failure_line = %(#{@lint_failure.description} at span #{@lint_failure.location[0]}:#{@lint_failure.location[1]})
  end

  def prompt
    <<-PROMPT
    You are an expert at remediating lint errors in source code.
    Generate a fix for the following lint failure in the provided source code.
    Only fix one specified lint failure at a time, at the given position.

    Source code:
    #{@source_code}

    Lint failure:
    #{@failure_line}

    Additional instructions (if any):
    #{@additional_instructions}

    For the fix provide:
    - description: A brief description of the change and why it is important.
    - fixed: the fixed source code with the issue resolved.
    - impact: A description of how the fix impacts the following assistive technologies:
      - Screen readers
      - Voice recognition
      - Switch devices
      - Magnifiers
      - Keyboard only

    Provide your response is an object containing the above attributes.
    PROMPT
  end
end
