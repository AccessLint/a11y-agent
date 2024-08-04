class FixA11yGenerator < Sublayer::Generators::Base
  llm_output_adapter type: :single_string,
                     name: 'fix_template_content_based_on_a11y_issue',
                     description: 'Given a web document template and an accessibility issue, generate a new file with the issue fixed.'

  def initialize(contents:, issue:, extension: '', additional_prompt: nil)
    @extension = extension
    @contents = contents
    @issue = issue
    @additional_prompt = additional_prompt
  end

  def generate
    super
  end

  def prompt
    <<~PROMPT
      Given the following #{@extension} template contents and an
      accessibility issue, generate a new #{@extension} file with the
      issue fixed, leaving the rest of the contents unchanged.

      #{@extension} code:
      #{@contents}

      Accessibility issue:
      #{@issue}

      Additional user instructions (if any):
      #{@additional_prompt || 'None'}

      Return the contents with the issue fixed.
    PROMPT
  end
end
