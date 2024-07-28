class FixA11yGenerator < Sublayer::Generators::Base
  llm_output_adapter type: :single_string,
    name: "fix_accessibility_issue_based_on_a11y_issue",
    description: "Given a JSX file and an accessibility issue, generate a new JSX file with the issue fixed."

  def initialize(contents:, issue:, additional_prompt: nil)
    @contents = contents
    @issue = issue
    @additional_prompt = additional_prompt
  end

  def generate
    super
  end

  def prompt
    <<~PROMPT
      Given the following JSX contents and an individual accessibility issue, generate a new JSX file with the individual issue fixed, leaving the rest of the contents unchanged.:

      Code:
      #{@contents}

      Accessibility issue:
      #{@issue}

      Additional user instructions (if any):
      #{@additional_prompt || "None"}

      Return the JSX contents with the issue fixed.
    PROMPT
  end
end