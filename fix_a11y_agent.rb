require "open3"
require "sublayer"
require "diffy"
require "json"
require "fileutils"
require_relative "./fix_a11y_generator"

Sublayer.configuration.ai_provider = Sublayer::Providers::OpenAI
Sublayer.configuration.ai_model = "gpt-4o-mini"

module Sublayer
  module Agents
    class FixA11yAgent < Base
      def initialize
        @accessibility_issues = []
      end

      trigger_on_files_changed do
        ["./trigger.txt"]
      end

      check_status do
        stdout, stderr, status = Open3.capture3("axe --exit --stdout http://localhost:8080")
        
        @axe_output = stdout
        @accessibility_issues = JSON.parse(stdout)[0]["violations"]

        formatted_issues = @accessibility_issues.map { |issue| issue["description"] }.join("\n\n")

        @accessibility_issues.empty? ? puts("No accessibility issues found") : puts("Found #{@accessibility_issues.length} accessibility issues: \n\n#{formatted_issues}")
      end

      goal_condition do
        @accessibility_issues.empty?
      end

      step do
        if @accessibility_issues.empty?
          system("git checkout -- index.html")
        end

        contents = File.read("./index.html")

        fixed = FixA11yGenerator.new(contents: contents, issues: @accessibility_issues).generate

        puts Diffy::Diff.new(contents, fixed).to_s(:color)

        File.write("./index.html", fixed)

        FileUtils.touch("./trigger.txt")
      end

      private

      def parse_axe_output(output:)
        JSON.parse(output)[0]["violations"]
      end
    end
  end
end

Sublayer::Agents::FixA11yAgent.new.run