class FixA11yGenerator < Sublayer::Generators::Base
  llm_output_adapter type: :single_string,
    name: "fix_accessibility_issues_based_on_axe_output",
    description: "Given an HTML file and a list of accessibility issues, generate a new HTML file with the issues fixed."

  def initialize(contents:, issues:)
    @contents = contents
    @issues = issues
  end

  def generate
    super
  end

  def prompt
    <<~PROMPT
      Given the following HTML contents and accessibility issues, generate a new HTML file with the issues fixed:
      HTML contents:
      #{@contents}

      Accessibility issues:
      #{@issues}

      Return the fixed HTML contents.
    PROMPT
  end
end