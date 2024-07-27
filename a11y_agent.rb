require "diffy"
require "fileutils"
require "json"
require "open3"
require "sublayer"
require 'dotenv/load'
require_relative "./fix_a11y_generator"

Sublayer.configuration.ai_provider = Sublayer::Providers::OpenAI
Sublayer.configuration.ai_model = "gpt-4o-mini"

module Sublayer
  module Agents
    class A11yAgent < Base
      def initialize(file:)
        @accessibility_issues = []
        @issue_types = []
        @file = file
        @file_contents = File.read(@file)
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
        puts "🎉 All accessibility issues have been fixed!" if @accessibility_issues.empty?
        @accessibility_issues.empty?
      end

      step do
        @accessibility_issues.each_with_index do |issue|
          contents = File.read("#{@file}")

          user_input = nil
          fixed = nil
          additional_prompt = nil

          until user_input == "y" || user_input == "n"
            puts "🔧 Fixing issue: #{issue}"

            result = FixA11yGenerator.new(contents: contents, issue: issue, additional_prompt: additional_prompt).generate
            puts Diffy::Diff.new(contents, result).to_s(:color)

            puts "🤷 Approve? ([y]es/[n]o/[r]etry)"
            user_input = $stdin.gets.chomp

            case user_input
            when "y"
              fixed = result
            when "n"
              fixed = contents
            when "r"
              puts "Add instructions for fixing the issue:"
              additional_prompt = $stdin.gets.chomp
              fixed = nil
            end
          end

          contents = fixed
          File.write(@file, contents)
          # system("git commit -am'Fix #{issue}'")
        end

        puts "✅ Complete diff:"
        puts Diffy::Diff.new(@file_contents, File.read(@file)).to_s(:color)

        puts "🎉 Done!"
      end
    end
  end
end

Sublayer::Agents::A11yAgent.new(file: ARGV[0]).run