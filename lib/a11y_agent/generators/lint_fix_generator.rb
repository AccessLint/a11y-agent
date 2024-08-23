# frozen_string_literal: true

require 'dotenv/load'
require 'sublayer'

class LintFixGenerator < Sublayer::Generators::Base
  llm_output_adapter type: :list_of_named_strings,
                     name: 'lint_fixes',
                     description: 'A list of steps to fix lint failures',
                     item_name: 'lint_fix',
                     attributes: [
                       {
                         name: 'description',
                         description: 'A brief description of the fix'
                       },
                       {
                         name: 'fix',
                         description: 'the code with the fix applied'
                       }
                     ]

  def initialize(lint_failures:, source_code:)
    super()
    @source_code = source_code
    @lint_failures = lint_failures
    @failure_lines = @lint_failures.map do |d|
      %(#{d.description} at span #{d.location[0]}:#{d.location[1]})
    end
  end

  def prompt
    <<-PROMPT
    You are an expert at breaking down tasks into step-by-step instructions with associated changes.
    Please generate a list of steps to complete the following task:

    Fix the following lint failures in the provided source code.

    Source code:
    #{@source_code}

    Lint failures:
    #{@failure_lines.join("\n")}

    For each step, provide:
    - description: A brief description of what the step accomplishes
    - fix: The exact change to apply to the source code to fix the lint issue

    Provide your response as a list of objects, each containing the above attributes.
    Ensure the steps are in the correct order to complete the task successfully.
    PROMPT
  end
end
