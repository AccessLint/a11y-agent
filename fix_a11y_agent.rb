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
      def initialize(file:)
        @accessibility_issues = []
        @issue_types = []
        @file = file
      end

      trigger_on_files_changed do
        ["./trigger.txt"]
      end

      check_status do
        stdout, stderr, status = Open3.capture3("eslint #{@file}")

        @accessibility_issues = stdout.include?("jsx-a11y") ? stdout.split("jsx-a11y") : []
        @accessibility_issues.pop

        if !@accessibility_issues.empty?
          puts "🚨 Found #{@accessibility_issues.length} accessibility issues"
        end
      end

      goal_condition do
        @accessibility_issues.empty?
      end

      step do
        @accessibility_issues.each_with_index do |issue|
          contents = File.read("#{@file}")

          approved = nil
          fixed = nil

          until approved == "y" || approved == "skip"
            puts "🔧 Fixing issue: #{issue}"

            result = FixA11yGenerator.new(contents: contents, issue: issue).generate
            puts Diffy::Diff.new(contents, result).to_s(:color)

            puts "🤷 Approve? (y/n/skip)"
            approved = $stdin.gets.chomp

            if approved == "y"
              fixed = result
            end
          end

          puts "✅ Complete diff:"

          puts Diffy::Diff.new(contents, fixed).to_s(:color)
          contents = fixed
          File.write(@file, contents)
          system("git commit -am'Fix #{issue}'")
        end
      end
    end
  end
end

Sublayer::Agents::FixA11yAgent.new(file: ARGV[0]).run