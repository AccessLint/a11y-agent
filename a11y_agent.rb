require "diffy"
require "fileutils"
require "json"
require "open3"
require "rainbow/refinement"
require "sublayer"
require 'dotenv/load'
require_relative "./fix_a11y_generator"

Diffy::Diff.default_format = :color

# Sublayer.configuration.ai_provider = Sublayer::Providers::OpenAi
# Sublayer.configuration.ai_model = "gpt-4o-mini"

# Sublayer.configuration.ai_provider = Sublayer::Providers::Gemini
# Sublayer.configuration.ai_model = "gemini-1.5-flash-latest"

Sublayer.configuration.ai_provider = Sublayer::Providers::Claude
Sublayer.configuration.ai_model = "claude-3-haiku-20240307"

module Sublayer
  module Agents
    class A11yAgent < Base
      using Rainbow

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
        stdout, stderr, status = Open3.capture3("eslint #{@file} --format stylish")

        @accessibility_issues = stdout.include?("jsx-a11y") ? stdout.split("\n")[2..-1] : []
        @accessibility_issues = @accessibility_issues.map { |issue| issue.gsub(/\s+/, ' ').strip }

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
            puts "🔧 Attempting a fix: #{issue}"
            result = FixA11yGenerator.new(contents: contents, issue: issue, additional_prompt: additional_prompt).generate
            result << "\n" unless result.end_with?("\n")

            Diffy::Diff.new(contents, result).each_chunk do |chunk|
              case chunk
              when /^\+/
                print chunk.to_s.green
              when /^-/
                print chunk.to_s.red
              else
                puts "..."
              end
            end

            puts "🤷 Approve? ([y]es/[n]o/[r]etry)"
            user_input = $stdin.gets.chomp

            case user_input
            when "y"
              fixed = result
            when "n"
              fixed = contents
            when "r"
              puts "What needs to change?"
              additional_prompt = $stdin.gets.chomp
              fixed = nil
            end
          end

          contents = fixed

          puts "Writing to file..."
          File.write(@file, contents)
        end

        puts "🎉 Done!"
        puts "✅ Complete diff:"
        puts Diffy::Diff.new(@file_contents, File.read(@file)).to_s
      end
    end
  end
end

Sublayer::Agents::A11yAgent.new(file: ARGV[0]).run