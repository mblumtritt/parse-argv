# frozen_string_literal: true

require 'rspec/core'
require_relative '../lib/parse-argv'

$stdout.sync = $stderr.sync = true

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
end

ParseArgv.on_error # disable default error handling
