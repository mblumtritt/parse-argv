# frozen_string_literal: true

require_relative '../helper'
require 'date'

RSpec.describe 'argument conversion' do
  subject(:result) { ParseArgv.from("usage: test:\n --opt <value> some", argv) }

  let(:value) { result.as(type, :value) }

  context ':integer' do
    let(:type) { :integer }
    let(:argv) { %w[--opt 16] }

    it 'returns the correct value' do
      expect(value).to eq 16
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt invalid] }

      it 'returns zero' do
        expect(value).to be_zero
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end

      context 'when a default is specified' do
        it 'returns the default value' do
          expect(result.as(:integer, :value, default: 21)).to eq 21
        end
      end
    end
  end

  context ':float' do
    let(:type) { :float }
    let(:argv) { %w[--opt 16.5] }

    it 'returns the correct value' do
      expect(value).to eq 16.5
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt invalid] }

      it 'returns zero' do
        expect(value).to be_zero
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end
    end
  end

  context ':positive' do
    let(:type) { :positive }
    let(:argv) { %w[--opt 16] }

    it 'returns the correct value' do
      expect(value).to eq 16
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt:-16] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: positive number expected - <value>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end
    end
  end

  context ':negative' do
    let(:type) { :negative }
    let(:argv) { %w[--opt:-16] }

    it 'returns the correct value' do
      expect(value).to eq(-16)
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt 16] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: negative number expected - <value>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end
    end
  end

  context ':float_positive' do
    let(:type) { :float_positive }
    let(:argv) { %w[--opt 16.5] }

    it 'returns the correct value' do
      expect(value).to eq 16.5
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt:-16.1] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: positive float number expected - <value>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end
    end
  end

  context ':float_negative' do
    let(:type) { :float_negative }
    let(:argv) { %w[--opt:-16.5] }

    it 'returns the correct value' do
      expect(value).to eq(-16.5)
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt 16.1] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: negative float number expected - <value>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end
    end
  end

  context ':string' do
    let(:type) { :string }
    let(:argv) { %w[--opt some] }

    it 'returns the correct value' do
      expect(value).to eq 'some'
    end

    context 'when an invalid value is given' do
      let(:argv) { ['--opt', ''] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument can not be empty - <value>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end
    end
  end

  context ':regexp' do
    let(:type) { :regexp }
    let(:argv) { %w[--opt \Atest.*] }

    it 'returns the correct value' do
      expect(value).to eq(/\Atest.*/)
    end

    context 'when an invalid value is given' do
      let(:argv) { ['--opt', '/some[/'] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: invalid regular expression; ' \
            'premature end of char-class: /some[/ - <value>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end
    end
  end

  context ':date' do
    let(:type) { :date }
    let(:argv) { %w[--opt 2022-01-02] }

    it 'returns the correct value' do
      expect(value).to eq Date.new(2022, 1, 2)
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt invalid] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument must be a date - <value>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end
    end

    today = Date.today
    {
      '0131' => Date.new(today.year, 1, 31),
      '20220131' => Date.new(2022, 1, 31),
      '17' => Date.new(today.year, today.month, 17),
      'may-12' => Date.new(today.year, 5, 12),
      '1.april' => Date.new(today.year, 4, 1)
    }.each_pair do |arg, expected|
      context "when a shorthand Date is given like '#{arg}'" do
        let(:argv) { ['--opt', arg] }

        it "converts to a Date: #{expected}" do
          expect(value).to eq expected
        end
      end
    end
  end

  context ':time' do
    let(:type) { :time }
    let(:argv) { ['--opt', '2022-01-02 13:14:15 GMT'] }

    it 'returns the correct value' do
      expect(value).to eq Time.new(2022, 1, 2, 13, 14, 15, 0)
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt invalid] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument must be a time - <value>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end
    end

    now = Time.now
    {
      '0131' => Time.new(now.year, 1, 31, 0, 0, 0, now.utc_offset),
      '13:14' => Time.new(now.year, now.month, now.mday, 13, 14),
      '13:14 utc+2' => Time.new(now.year, now.month, now.mday, 13, 14, 0, 7200),
      '17 13:14' => Time.new(now.year, now.month, 17, 13, 14),
      'may-12 13:14' => Time.new(now.year, 5, 12, 13, 14)
    }.each_pair do |arg, expected|
      context "when a shorthand Time is given like '#{arg}'" do
        let(:argv) { ['--opt', arg] }

        it "converts to a Time: #{expected}" do
          expect(value).to eq expected
        end
      end
    end
  end

  context ':file_name' do
    let(:type){ :file_name }
    let(:argv) { %w[--opt file.ext] }

    it 'returns the correct value' do
      expect(value).to eq File.join(Dir.pwd, 'file.ext')
    end

    context 'when an invalid value is given' do
      let(:argv) { ['--opt', ''] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument can not be empty - <value>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end
    end
  end

  context ':file' do
    let(:type){ :file }
    let(:argv) { ['--opt', __FILE__] }

    it 'returns the correct value' do
      expect(value).to eq __FILE__
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt invalid] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: file does not exist - <value>'
        )
      end
    end

    context 'when not a file is given' do
      let(:argv) { ['--opt', __dir__] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument must be a file - <value>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end
    end

    context 'when an additional file attribute is given' do
      let(:value) { result.as(:file, :value, :readable) }

      it 'returns the correct value' do
        expect(value).to eq __FILE__
      end

      context 'when the attribute is not valid for the file' do
        let(:value) { result.as(:file, :value, :symlink) }

        it 'raises an error' do
          expect { value }.to raise_error(
            ParseArgv::Error,
            'test: file attribute `symlink` not satisfied - <value>'
          )
        end
      end
    end
  end

  context ':directory' do
    let(:type){ :directory }
    let(:argv) { ['--opt', __dir__] }

    it 'returns the correct value' do
      expect(value).to eq __dir__
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt invalid] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: directory does not exist - <value>'
        )
      end
    end

    context 'when not a file is given' do
      let(:argv) { ['--opt', __FILE__] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument must be a directory - <value>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end
    end

    context 'when an additional file attribute is given' do
      let(:value) { result.as(:directory, :value, :readable) }

      it 'returns the correct value' do
        expect(value).to eq __dir__
      end

      context 'when the attribute is not valid for the directory' do
        let(:value) { result.as(:directory, :value, :symlink) }

        it 'raises an error' do
          expect { value }.to raise_error(
            ParseArgv::Error,
            'test: directory attribute `symlink` not satisfied - <value>'
          )
        end
      end
    end
  end

  context ':array' do
    let(:type){ :array }
    let(:argv) { ['--opt', '[aaaa,  bbb,cc  ,,d]'] }

    it 'returns the correct value' do
      expect(value).to eq %w[aaaa bbb cc d]
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt []] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument can not be empty - <value>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end
    end
  end

  context 'Array<String>' do
    let(:type){ %w[one two three] }
    let(:argv) { %w[--opt two] }

    it 'returns the correct value' do
      expect(value).to eq 'two'
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt invalid] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument must be one of `one`, `two`, `three` - <value>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end

      context 'when a default is specified' do
        let(:value) { result.as(%w[one two three], :value, default: 'seven') }

        it 'returns the default value' do
          expect(value).to eq 'seven'
        end
      end
    end
  end

  context '[<type>]' do
    let(:type){ [:positive] }
    let(:argv) { %w[--opt [1,2,3]] }

    it 'returns the correct value' do
      expect(value).to eq [1, 2, 3]
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt [1,2,-3]] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: positive number expected - <value>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end
    end
  end

  context 'Regular Expression' do
    let(:type){ /\Ate+st\z/ }
    let(:argv) { %w[--opt teeeeest] }

    it 'returns the correct value' do
      expect(value).to eq 'teeeeest'
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt toest] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument must match (?-mix:\Ate+st\z) - <value>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end
    end

    context 'when the :match option is given' do
      let(:value) { result.as(/\At(e+)st\z/, :value, :match) }

      it 'returns the Regexp::Match' do
        expect(value).to eq /\At(e+)st\z/.match('teeeeest')
      end
    end
  end

  context 'custom types can be defined' do
    before do
      ParseArgv::Conversion.define(:my) do |arg, &err|
        arg == 'test' || err['not a custom type']
        arg
      end
    end

    let(:type) { :my }
    let(:argv) { %w[--opt test] }

    it 'returns the correct value' do
      expect(value).to eq 'test'
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt invalid] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: not a custom type - <value>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end
    end
  end

  context 'aliased conversion types' do
    {
      :int => :integer,
      Integer => :integer,
      Float => :float,
      :str => :string,
      String => :string,
      :regex => :regexp,
      Regexp => :regexp,
      File => :file,
      :dir => :directory,
      Dir => :directory,
      Array => :array
    }.each_pair do |aliased, type|
      it "defines #{aliased.inspect} as alias for type :#{type}" do
        expect(
          ParseArgv::Conversion.for(aliased)
        ).to be ParseArgv::Conversion.for(type)
      end
    end
  end
end
