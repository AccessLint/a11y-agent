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
        @issue_types = []
      end

      trigger_on_files_changed do
        ["./trigger.txt"]
      end

      check_status do
        stdout, stderr, status = Open3.capture3("axe --exit --stdout http://localhost:8080")
        @axe_output = stdout
        @accessibility_issues = JSON.parse(stdout)[0]["violations"]

        if !@accessibility_issues.empty? 
          @issue_types = @accessibility_issues.map { |issue| issue["id"] }
          formatted_issues = @accessibility_issues.map { |issue| issue["description"] }.join("\n\n")
          puts "Found #{@accessibility_issues.length} accessibility issues: \n\n#{formatted_issues}"
        end
      end

      goal_condition do
        @accessibility_issues.empty?
      end

      step do
        contents = File.read("./public/index.html")

        @issue_types.each do |issue_type|
          puts "Fixing issue: #{issue_type}"
          fixed = FixA11yGenerator.new(contents: contents, issues: @accessibility_issues.select { |issue| issue["id"] == issue_type }.to_json).generate
          puts Diffy::Diff.new(contents, fixed).to_s(:color)
          contents = fixed
          File.write("./public/index.html", contents)
          system("git commit -am'Fix #{issue_type}'")
        end
      end
    end
  end
end

Sublayer::Agents::FixA11yAgent.new.run