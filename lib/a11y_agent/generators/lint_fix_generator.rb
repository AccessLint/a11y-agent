# frozen_string_literal: true

require 'sublayer'

class LintFixGenerator < Sublayer::Generators::Base
  def initialize(source_code:, lint_failures:)
    @source_code = source_code
    @lint_failures = lint_failures
  end

  def prompt
    <<~PROMPT
      Given this source code and corresponding lint failures,
      return a fixed version of the source code.

      The code: #{@source_code}

      The lint failures: #{@lint_failures}
    PROMPT
  end
end
