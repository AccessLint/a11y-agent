# frozen_string_literal: true

require 'dotenv/load'
require 'diffy'
require 'fileutils'
require 'json'
require 'open3'
require 'rainbow/refinement'
require 'sublayer'
require 'tty-prompt'
require_relative '../generators/fix_a11y_generator'
require_relative '../generators/hydrate_document_generator'

Diffy::Diff.default_format = :color

# Sublayer.configuration.ai_provider = Sublayer::Providers::OpenAI
# Sublayer.configuration.ai_model = 'gpt-4o-mini'

# Sublayer.configuration.ai_provider = Sublayer::Providers::Gemini
# Sublayer.configuration.ai_model = "gemini-1.5-flash-latest"

Sublayer.configuration.ai_provider = Sublayer::Providers::Claude
Sublayer.configuration.ai_model = 'claude-3-haiku-20240307'

CHOICES = [
  { key: 'y', name: 'approve and continue', value: :yes },
  { key: 'n', name: 'skip this change', value: :no },
  { key: 'r', name: 'retry with optional instructions', value: :retry },
  { key: 'q', name: 'quit; stop making changes', value: :quit }
].freeze

module Sublayer
  module Agents
    class A11yAgent < Base
      using Rainbow

      def initialize(file:)
        @accessibility_issues = []
        @issue_types = []
        @file = file
        @file_contents = File.read(@file)
        @prompt = TTY::Prompt.new
      end

      trigger_on_files_changed do
        ['./trigger.txt']
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
        exit 0
      end

      private

      def run_axe(file: @file)
        stdout, _stderr, _status = Open3.capture3("yarn --silent ts-node lib/bin/axe.ts #{file}")
        JSON.parse(stdout)
      end

      def load_issues
        Tempfile.create(['', File.extname(@file)]) do |tempfile|
          tempfile.write(hydrated_file)
          tempfile.rewind

          @accessibility_issues = run_axe(file: tempfile.path).map do |issue|
            %w[id impact tags helpUrl].each { |key| issue.delete(key) }
            issue
          end
        end

        puts "🚨 Found #{@accessibility_issues.length} accessibility issues" unless @accessibility_issues.empty?
      end

      def hydrated_file
        puts "Loading fake data into #{@file}"
        hydrated = HydrateDocumentGenerator.new(contents: @file_contents, extension: File.extname(@file)).generate
        hydrated << "\n" until hydrated.end_with?("\n")

        print_diff(contents: @file_contents, fixed: hydrated, message: '📊 Changes made:')
        hydration_approved = @prompt.yes? 'Continue with updates?'
        hydrated = @file_contents unless hydration_approved
        hydrated
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
          attempt = @prompt.yes? "Attempt to fix these issues in #{@file}?"
          next unless attempt

          until %i[yes no].include?(user_input)
            puts '🔧 Attempting a fix...'
            result = FixA11yGenerator.new(contents: updated_contents, issue: node_issue, extension: File.extname(@file),
                                          additional_prompt:).generate
            result << "\n" unless result.end_with?("\n")

            print_chunks(contents: updated_contents, fixed: result)

            user_input = @prompt.expand('Approve changes?', CHOICES)

            case user_input
            when :yes
              fixed = result
            when :no
              fixed = updated_contents
            when :retry
              additional_prompt = @prompt.ask('Additional instructions:')
              fixed = nil
            when :quit
              puts 'Quitting...'
              exit 0
            end
          end

          puts '📝 Saving changes...'
          File.write(@file, fixed) if fixed
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
