# frozen_string_literal: true

require 'dotenv/load'
require 'fileutils'
require 'json'
require 'open3'
require 'sublayer'
require_relative '../actions/tty_prompt_action'
require_relative '../actions/user_input_action'
require_relative '../generators/code_replacement_generator'
require_relative '../generators/fix_a11y_generator'

# Sublayer.configuration.ai_provider = Sublayer::Providers::OpenAI
# Sublayer.configuration.ai_model = 'gpt-4o-mini'

# Sublayer.configuration.ai_provider = Sublayer::Providers::Gemini
# Sublayer.configuration.ai_model = "gemini-1.5-flash-latest"

Sublayer.configuration.ai_provider = Sublayer::Providers::Claude
Sublayer.configuration.ai_model = 'claude-3-haiku-20240307'

module Sublayer
  module Agents
    class A11yAgent < Base
      def initialize(file:)
        super()
        @accessibility_issues = []
        @issue_types = []
        @file = file
        @file_contents = File.read(@file)
        @tty_prompt = TtyPromptAction.new
      end

      trigger_on_files_changed do
        []
      end

      check_status do
        load_issues unless run_axe.empty?
      end

      goal_condition do
        puts "🤷 No accessibility issues found in #{@file}" if @accessibility_issues.empty?
        exit 0 if @accessibility_issues.empty?
      end

      step do
        @accessibility_issues.each { |issue| fix_issue_and_save(issue:) }
      end

      private

      def run_axe(file: @file)
        stdout, _stderr, _status = Open3.capture3("yarn --silent ts-node lib/bin/axe.ts #{file}")
        JSON.parse(stdout)
      end

      def load_issues
        Tempfile.create(['', File.extname(@file)]) do |tempfile|
          tempfile.write(code_replaced)
          tempfile.rewind

          @accessibility_issues = run_axe(file: tempfile.path).map do |issue|
            %w[id impact tags helpUrl].each { |key| issue.delete(key) }
            issue
          end
        end

        puts "🚨 Found #{@accessibility_issues.length} accessibility issues" unless @accessibility_issues.empty?
      end

      def code_replaced
        puts "Loading fake data into #{@file}"

        updated, code = UserInputAction.new(generator: CodeReplacementGenerator.new(contents: @file_contents,
                                                                                    extension: File.extname(@file))).call

        return updated if code == :success

        @file_contents
      end

      def fix_issue_and_save(issue:)
        updated_contents = File.read(@file)

        issue['nodes'].each do |node|
          user_input = nil
          fixed = nil
          additional_prompt = nil
          summary = node['failureSummary']
          node_issue = [summary, issue['help'], node['html']].join("\n\n")

          puts "🔍 #{issue['help']}"
          attempt = @tty_prompt.yes? "Attempt to fix these issues in #{@file}?"
          next unless attempt

          puts '🔧 Attempting a fix...'
          result << "\n" unless result.end_with?("\n")

          print_chunks(contents: updated_contents, fixed: result)

          fixed, code = UserInputAction.new(generator: FixA11yGenerator.new(contents: updated_contents,
                                                                            issue: node_issue)).call
          result =
            case code
            when :success
              fixed
            when :quit
              exit 0
            end

          puts '📝 Saving changes...'
          File.write(@file, result) if result
        end
      end

      def print_diff(contents:, fixed:, message: '')
        puts message
        puts Diffy::Diff.new(contents, fixed)
      end

      def print_chunks(contents:, fixed:)
        Diffy::Diff.new(contents, fixed).each_chunk do |chunk|
          case chunk
          when /^\+/
            print chunk.to_s.green
          when /^-/
            print chunk.to_s.red
          else
            lines = chunk.to_s.split("\n")
            puts lines[0..2].join("\n")
            puts '...'
            puts lines[-3..].join("\n") if lines.length > 5
          end
        end
      end
    end
  end
end
