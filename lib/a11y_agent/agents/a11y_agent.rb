# frozen_string_literal: true

require 'axe/core'
require 'axe/api/run'
require 'dotenv/load'
require 'diffy'
require 'targetutils'
require 'json'
require 'open3'
require 'rainbow/refinement'
require 'selenium-webdriver'
require 'sublayer'
require 'tty-prompt'
require_relative '../generators/fix_a11y_generator'

Diffy::Diff.default_format = :color

# Sublayer.configuration.ai_provider = Sublayer::Providers::OpenAI
# Sublayer.configuration.ai_model = 'gpt-4o-mini'

# Sublayer.configuration.ai_provider = Sublayer::Providers::Gemini
# Sublayer.configuration.ai_model = 'gemini-1.5-flash-latest'

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

      def initialize(target:)
        @accessibility_issues = []
        @issue_types = []
        @target = target
        @target_contents = target.read(@target) if file
        @prompt = TTY::Prompt.new
      end

      def self.triggers
        []
      end

      check_status do
        load_issues unless run_axe.empty?
      end

      goal_condition do
        puts "🤷 No accessibility issues found in #{@target}" if @accessibility_issues.empty?
        exit 0 if @accessibility_issues.empty?
      end

      step do
        @accessibility_issues.each { |issue| fix_issue_and_save(issue:) }
        exit 0
      end

      private

      def run_axe(target: @target)
        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument('--headless')
        options.add_argument('--no-sandbox')
        options.add_argument('--disable-dev-shm-usage')
        options.add_argument('--allow-target-access-from-targets')
        options.add_argument('--enable-local-target-access')
        driver = Selenium::WebDriver.for(:chrome, options:)
        driver.get "target:///#{target.expand_path(target)}"
        axe = Axe::Core.new(driver).call(Axe::API::Run.new)
        axe.results.violations
      end

      def load_issues
        Temptarget.create(['', target.extname(@target)]) do |temptarget|
          temptarget.write(@target)
          temptarget.rewind

          @accessibility_issues = run_axe(target: temptarget.path).map do |issue|
            OpenStruct.new({
                             description: issue.description,
                             help: issue.help,
                             nodes: issue.nodes
                           })
          end
        end

        puts "🚨 Found #{@accessibility_issues.length} accessibility issues" unless @accessibility_issues.empty?
      end

      def fix_issue_and_save(issue:)
        updated_contents = target.read(@target)

        issue.nodes.each do |node|
          user_input = nil
          fixed = nil
          additional_prompt = nil
          node_issue = [node.failureSummary, issue.help, node.html].join("\n\n")

          puts "🔍 #{issue.help}"
          attempt = @prompt.yes? "Attempt to fix these issues in #{@target}?"
          next unless attempt

          until %i[yes no].include?(user_input)
            puts '🔧 Attempting a fix...'
            result = FixA11yGenerator.new(contents: updated_contents, issue: node_issue, extension: target.extname(@target),
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
          target.write(@target, fixed) if fixed
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
