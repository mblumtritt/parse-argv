# frozen_string_literal: true

require_relative './lib/parse-argv/version'

Gem::Specification.new do |spec|
  spec.name = 'parse-argv'
  spec.version = ParseArgv::VERSION
  spec.summary = 'A command line parser that only needs your help text.'
  spec.description = <<~DESCRIPTION
    Just write the help text for your application and ParseArgv will take care
    of your command line. It works sort of the other way around than OptParse,
    where you write a lot of code to get a command line parser and generated
    help text. ParseArgv simply takes your help text and parses the command
    line and presents you the results.

    You can use ParseArgv for simpler programs just as well as for CLI with
    multi-level sub-commands (git-like commands). ParseArgv is easy to use,
    fast and also helps you convert the data types of command line arguments.
  DESCRIPTION

  spec.author = 'Mike Blumtritt'
  spec.license = 'BSD-3-Clause'
  spec.homepage = 'https://github.com/mblumtritt/parse-argv'
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['documentation_uri'] = 'https://rubydoc.info/gems/parse-argv'

  spec.required_ruby_version = '>= 2.7.0'

  spec.files = Dir['lib/**/*'] + Dir['examples/*']
  spec.extra_rdoc_files = %w[ReadMe.md LICENSE]
end
