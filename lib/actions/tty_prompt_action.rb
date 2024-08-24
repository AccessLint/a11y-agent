# frozen_string_literal: true

require 'forwardable'
require 'tty-prompt'
require_relative './base_action'

class TtyPromptAction < BaseAction
  extend Forwardable

  def_delegators :@prompt, :expand, :ask, :yes?

  CHOICES = [
    { key: 'y', name: 'Yes', value: :yes },
    { key: 'n', name: 'No', value: :no },
    { key: 'r', name: 'Retry', value: :retry },
    { key: 'q', name: 'Quit', value: :quit }
  ].freeze

  def initialize
    super
    @prompt = TTY::Prompt.new
  end

  def call
    expand('Continue with changes?', CHOICES)
  end
end
