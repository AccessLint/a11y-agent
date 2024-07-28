require 'diffy'
require 'fileutils'
require 'json'
require 'open3'
require 'rainbow/refinement'
require 'sublayer'
require 'tty-prompt'
require 'dotenv/load'
require_relative './fix_a11y_generator'

Diffy::Diff.default_format = :color

# Sublayer.configuration.ai_provider = Sublayer::Providers::OpenAi
# Sublayer.configuration.ai_model = "gpt-4o-mini"

# Sublayer.configuration.ai_provider = Sublayer::Providers::Gemini
# Sublayer.configuration.ai_model = "gemini-1.5-flash-latest"

Sublayer.configuration.ai_provider = Sublayer::Providers::Claude
Sublayer.configuration.ai_model = 'claude-3-haiku-20240307'

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
        ['./trigger.txt']
      end

      check_status do
        puts "🔍 Checking accessibility issues in #{@file}..."
        stdout, _stderr, _status = Open3.capture3("eslint #{@file} --format stylish")

        @accessibility_issues = stdout.split("\n")[2..]
        @accessibility_issues = @accessibility_issues.map { |issue| issue.gsub(/\s+/, ' ').strip }

        puts "🚨 Found #{@accessibility_issues.length} accessibility issues" unless @accessibility_issues.empty?
      end

      goal_condition do
        puts '🎉 All accessibility issues have been fixed!' if @accessibility_issues.empty?
        @accessibility_issues.empty?
      end

      step do
        prompt = TTY::Prompt.new

        @accessibility_issues.each do |issue|
          contents = File.read(@file)

          user_input = nil
          fixed = nil
          additional_prompt = nil

          until %i[yes no].include?(user_input)
            puts "🔧 Attempting a fix: #{issue}"
            result = FixA11yGenerator.new(contents:, issue:,
                                          additional_prompt:).generate
            result << "\n" unless result.end_with?("\n")

            Diffy::Diff.new(contents, result).each_chunk do |chunk|
              case chunk
              when /^\+/
                print chunk.to_s.green
              when /^-/
                print chunk.to_s.red
              else
                lines = chunk.to_s.split("\n")
                puts lines[0..2].join("\n")
                puts '...'
                puts lines[-3..].join("\n")
              end
            end

            choices = [
              { key: 'y', name: 'approve and continue', value: :yes },
              { key: 'n', name: 'skip this change', value: :no },
              { key: 'r', name: 'retry with optional instructions', value: :retry },
              { key: 'q', name: 'quit; stop making changes', value: :quit }
            ]

            user_input = prompt.expand('Approve changes?', choices)

            case user_input
            when :yes
              fixed = result
            when :no
              fixed = contents
            when :retry
              additional_prompt = prompt.ask('Additional instructions:')
              fixed = nil
            when :quit
              puts 'Quitting...'
              exit
            end
          end

          contents = fixed

          puts 'Writing to file...'
          File.write(@file, contents)
        end

        puts '🎉 Done!'
        puts '✅ Complete diff:'
        puts Diffy::Diff.new(@file_contents, File.read(@file))
      end
    end
  end
end

Sublayer::Agents::A11yAgent.new(file: ARGV[0]).run
