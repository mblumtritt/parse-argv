# frozen_string_literal: true

require 'date'
require_relative '../../helper'
require_relative 'shared'

RSpec.describe 'Conversion.define alias' do
  {
    Integer => :integer,
    Float => :float,
    Numeric => :number,
    String => :string,
    Regexp => :regexp,
    Array => :array,
    File => :file,
    Dir => :directory,
    Date => :date,
    Time => :time
  }.each_pair do |aliased, type|
    it "defines #{aliased.inspect} as alias for type :#{type}" do
      expect(ParseArgv::Conversion[aliased]).to be ParseArgv::Conversion[type]
    end
  end
end
