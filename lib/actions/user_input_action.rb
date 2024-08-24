# frozen_string_literal: true

require_relative './base_action'
require_relative './printer_action'
require_relative './tty_prompt_action'

class UserInputAction < BaseAction
  def initialize(generator:, injected_prompt: nil, printer: nil, tty_prompt: nil)
    super()
    @generator = generator
    @injected_prompt = injected_prompt
    @printer = printer || PrinterAction.new(base: @generator.base, updated: nil)
    @tty_prompt = tty_prompt || TtyPromptAction.new
  end

  def call
    updated = nil

    loop do
      if @injected_prompt
        @generator.update(attribute: :injected_prompt,
                          new_value: @injected_prompt)
      end

      updated = @generator.generate

      @printer = Printer.new(base: @generator.base, updated: fixed).call

      case @tty_prompt.expand('Continue with changes?', CHOICES)
      when :quit
        return :quit, nil
      when :yes
        return :success, updated
      when :retry
        @injected_prompt = @tty_prompt
                           .ask('Additional instructions:')
      end
    end
  end
end
