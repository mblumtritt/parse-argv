# frozen_string_literal: true

require 'rspec/core'
require_relative '../lib/parse-argv'

$stdout.sync = $stderr.sync = true

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
end

module Fixture
  ROOT = "#{__dir__}/fixtures"

  def self.file_name(name)
    name = name.to_s
    name = "#{name}.txt" if File.extname(name).empty?
    File.expand_path(name.to_s, ROOT)
  end

  def self.[](name)
    File.read(file_name(name))
  end
end
