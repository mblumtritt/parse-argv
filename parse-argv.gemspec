# frozen_string_literal: true

require_relative './lib/parse-argv/version'

Gem::Specification.new do |spec|
  spec.name = 'parse-argv'
  spec.version = ParseArgv::VERSION
  spec.summary = 'A command line parser that only needs your help text.'
  spec.description = <<~DESCRIPTION
    Just write the help text for your application and ParseArgv will take care
    of the command line for you. It's kind of the reverse of OptParse, where
    you code a lot to get a parser with help text support.
    ParseArgv works for simple commands, as well as for CLI with subcommands
    (git-like apps).
  DESCRIPTION

  spec.author = 'Mike Blumtritt'
  # spec.license = 'BSD-3-Clause'
  spec.homepage = 'https://github.com/mblumtritt/parse-argv'
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/parse-argv"

  spec.required_ruby_version = '>= 2.7.0'

  spec.files = Dir['/lib/**/*']
  spec.extra_rdoc_files = %w[ReadMe.md LICENSE]
end
