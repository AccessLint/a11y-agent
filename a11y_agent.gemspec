# frozen_string_literal: true

require_relative './lib/a11y_agent/version'

Gem::Specification.new do |spec|
  spec.name = 'a11y_agent'
  spec.version = A11yAgent::VERSION
  spec.authors = ['Cameron Cundiff']
  spec.email = 'cameron@accesslint.com'

  spec.summary = 'AI agent that fixes accessibility issues'
  spec.description = 'A11y Agent is a tool that helps you fix accessibility issues, using AI and user input.'
  spec.homepage =
    'https://github.com/accesslint/a11y-agent'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/accesslint/a11y-agent'

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github Gemfile])
    end
  end
  spec.bindir = 'bin'
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'diffy', '~> 3.4'
  spec.add_dependency 'rainbow', '~> 3.0'
  spec.add_dependency 'sublayer', '~> 0.1'
  spec.add_dependency 'tty-prompt', '~> 0.23'

  spec.add_development_dependency 'rake'
end
