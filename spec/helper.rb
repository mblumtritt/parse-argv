# frozen_string_literal: true

require 'rspec/core'
require_relative '../lib/parse-argv'

$stdout.sync = $stderr.sync = true
$VERBOSE = true
RSpec.configure { |config| config.disable_monkey_patching! }
ParseArgv.on_error(:raise)
