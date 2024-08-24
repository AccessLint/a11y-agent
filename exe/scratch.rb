#! /usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'tempfile'
require 'diffy'
require 'tty-prompt'
require 'rainbow/refinement'
require 'sidekiq'

using Rainbow

require_relative '../lib/a11y_agent/generators/confirmable_fix_generator'

Sublayer.configuration.ai_provider = Sublayer::Providers::Claude
Sublayer.configuration.ai_model = 'claude-3-5-sonnet-20240620'

source_code = <<~TSX
  import React from 'react';

  const AccessibilityFailuresExample = () => {
    const handleClick = () => {
      console.log('Clicked');
    };

    return (
      <div>
        {/* alt-text */}
        <img src="example.jpg" />

        {/* anchor-has-content */}
        <a></a>

        {/* aria-activedescendant-has-tabindex */}
        <div aria-activedescendant="child-1"></div>

        {/* aria-props */}
        <div aria-labeledby="label"></div>

        {/* aria-proptypes */}
        <div aria-expanded="yes"></div>

        {/* aria-role */}
        <div role="datepicker"></div>

        {/* aria-unsupported-elements */}
        <meta aria-hidden="true" />

        {/* click-events-have-key-events */}
        <div onClick={handleClick}></div>

        {/* heading-has-content */}
        <h1></h1>

        {/* html-has-lang */}
        <html></html>

        {/* iframe-has-title */}
        <iframe src="https://example.com"></iframe>

        {/* img-redundant-alt */}
        <img src="example.jpg" alt="image of example" />

        {/* interactive-supports-focus */}
        <div role="button" onClick={handleClick}></div>

        {/* label-has-associated-control */}
        <label>Name</label>
        <input type="text" />

        {/* media-has-caption */}
        <video src="example.mp4"></video>

        {/* mouse-events-have-key-events */}
        <div onMouseOver={() => console.log('hover')}></div>

        {/* no-access-key */}
        <button accessKey="s">Save</button>

        {/* no-autofocus */}
        <input type="text" autoFocus />

        {/* no-distracting-elements */}
        <marquee>This is distracting</marquee>

        {/* no-interactive-element-to-noninteractive-role */}
        <button role="presentation">Click me</button>

        {/* no-noninteractive-element-interactions */}
        <div onClick={handleClick}>Click me</div>

        {/* no-noninteractive-tabindex */}
        <div tabIndex="0">Focusable div</div>

        {/* no-onchange */}
        <select onChange={handleClick}></select>

        {/* no-redundant-roles */}
        <button role="button">Click me</button>

        {/* no-static-element-interactions */}
        <div onClick={handleClick} role="presentation">Click me</div>

        {/* role-has-required-aria-props */}
        <input type="checkbox" role="switch" />

        {/* scope */}
        <td scope="row">Data</td>

        {/* tabindex-no-positive */}
        <div tabIndex="2">Focusable div</div>
      </div>
    );
  };

  export default AccessibilityFailuresExample;

TSX

prompt = TTY::Prompt.new
lint_failures = []

Tempfile.create(['a11y', '.tsx']) do |file|
  file.write(source_code)
  file.rewind
  command = %(yarn --silent biome lint --reporter=json --only=a11y #{file.path})
  stdout, _stderr, _status = Open3.capture3(command, stdin_data: source_code)

  lint_failures = JSON.parse(stdout).fetch('diagnostics').map do |d|
    OpenStruct.new(
      description: d.fetch('description'),
      location: d.fetch('location').fetch('span'),
      snippet: d.fetch('location').fetch('sourceCode')[d.fetch('location').fetch('span')[0]..d.fetch('location').fetch('span')[1] - 1],
      advice: d.fetch('advices').fetch('advices').map do |a|
        a.fetch('log')[1][0].fetch('content') unless a.fetch('log', nil).nil?
      end
    )
  end
end

lint_failures.each do |lint_failure|
  additional_instructions = nil

  loop do
    result = ConfirmableFixGenerator.new(lint_failure:, source_code:,
                                         additional_instructions:).generate

    puts Diffy::Diff.new(source_code, result.fixed, context: 2).to_s(:color)

    input = prompt.expand('Apply the fix?', [
                            { key: 'y', name: 'Apply the fix', value: :fix },
                            { key: 'e', name: 'Explain why', value: :explain },
                            { key: 'r', name: 'Retry with optional instructions', value: :retry },
                            { key: 'q', name: 'Exit', value: :exit }
                          ])

    exit 0 if input == :exit

    if input == :retry
      additional_instructions = prompt.ask('Provide additional instructions:')
      next
    elsif input == :explain
      puts
      puts 'Explanation'.bright
      puts result.description
      puts

      continue = prompt.yes? 'Continue with the fix?'
      next unless continue
    end

    @source_code = result.fixed

    break
  end
end
