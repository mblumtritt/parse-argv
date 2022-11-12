# frozen_string_literal: true

require 'rspec/core'
require_relative '../lib/parse-argv'

$stdout.sync = $stderr.sync = $VERBOSE = true
RSpec.configure(&:disable_monkey_patching!)
ParseArgv.on_error(:raise)
