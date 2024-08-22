#! /usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/a11y_agent/generators/lint_fix_generator'

source_code = <<~JSX
  const App = () => {
    return (
      <div>
        <h1>Hello, world!</h1>
      </div>
    );
  };
JSX

lint_failures =

  LintFixGenerator.new.run
