# frozen_string_literal: true

require 'diffy'
require 'rainbow/refinement'
require_relative './base_action'

class PrinterAction < BaseAction
  using Rainbow

  Diffy::Diff.default_format = :color

  def initialize(base:, updated:)
    super
    @base = base
    @updated = updated
  end

  def call
    Diffy::Diff.new(@base, @updated).each_chunk do |chunk|
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
