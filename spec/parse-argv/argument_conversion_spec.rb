# frozen_string_literal: true

require_relative '../helper'

RSpec.describe 'argument convsersion' do
  subject(:result) { ParseArgv.from(help_text, argv) }

  let(:help_text) { <<~HELP }
    This is a demo for argument conversion.

    Usage: test

    Options:
      --int <int>       #to_i conversion
      --float <float>   #to_f conversion
      --pos <pos>       positive number
      --neg <neg>       negative number
      --fpos <fpos>     positive float number
      --fneg <fneg>     negative float number
      --str <str>       non-empty string
      --fname <fname>   non-empty relative file name
      --ary <ary>       array of given items
      --tary <tary>     array of items of given type
      --item <item>     one of [one, two, three]
      --match <match>   have to match /\Ate+st\z/
      --file <file>     existing file
      --dir <dir>       existing directory
      --regex <regex>   regular expression
      --custom <custom> custom type
  HELP

  context ':integer' do
    let(:value) { result.as(:integer, :int) }
    let(:argv) { %w[--int 16] }

    it 'returns the correct value' do
      expect(value).to eq 16
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--int invalid] }

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
        let(:value) { result.as(:integer, :int, default: 21) }

        it 'returns the default value' do
          expect(value).to eq 21
        end
      end
    end
  end

  context ':float' do
    let(:value) { result.as(:float, :float) }
    let(:argv) { %w[--float 16.5] }

    it 'returns the correct value' do
      expect(value).to eq 16.5
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--float invalid] }

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
    let(:value) { result.as(:positive, :pos) }
    let(:argv) { %w[--pos 16] }

    it 'returns the correct value' do
      expect(value).to eq 16
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--pos:-16] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: positive number expected - <pos>'
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
    let(:value) { result.as(:negative, :neg) }
    let(:argv) { %w[--neg:-16] }

    it 'returns the correct value' do
      expect(value).to eq(-16)
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--neg:16] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: negative number expected - <neg>'
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
    let(:value) { result.as(:float_positive, :fpos) }
    let(:argv) { %w[--fpos 16.5] }

    it 'returns the correct value' do
      expect(value).to eq 16.5
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--fpos:-16.1] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: positive float number expected - <fpos>'
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
    let(:value) { result.as(:float_negative, :fneg) }
    let(:argv) { %w[--fneg:-16.5] }

    it 'returns the correct value' do
      expect(value).to eq(-16.5)
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--fneg:16.1] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: negative float number expected - <fneg>'
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
    let(:value) { result.as(:string, :str) }
    let(:argv) { %w[--str some] }

    it 'returns the correct value' do
      expect(value).to eq 'some'
    end

    context 'when an invalid value is given' do
      let(:argv) { ['--str', ''] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument can not be empty - <str>'
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
    let(:value) { result.as(:regexp, :regex) }
    let(:argv) { ['--regex', '\Atest.*'] }

    it 'returns the correct value' do
      expect(value).to eq(/\Atest.*/)
    end

    context 'when an invalid value is given' do
      let(:argv) { ['--regex', '/some[/'] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: invalid regular expression; ' \
            'premature end of char-class: /some[/ - <regex>'
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

  context ':file_name' do
    let(:value) { result.as(:file_name, :fname) }
    let(:argv) { %w[--fname file.ext] }

    it 'returns the correct value' do
      expect(value).to eq File.join(Dir.pwd, 'file.ext')
    end

    context 'when an invalid value is given' do
      let(:argv) { ['--fname', ''] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument can not be empty - <fname>'
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
    let(:value) { result.as(:file, :file) }
    let(:argv) { ['--file', __FILE__] }

    it 'returns the correct value' do
      expect(value).to eq __FILE__
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--file invalid] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: file does not exist - <file>'
        )
      end
    end

    context 'when not a file is given' do
      let(:argv) { ['--file', __dir__] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument must be a file - <file>'
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
      let(:value) { result.as(:file, :file, :readable) }

      it 'returns the correct value' do
        expect(value).to eq __FILE__
      end

      context 'when the attribute is not valid for the file' do
        let(:value) { result.as(:file, :file, :symlink) }

        it 'raises an error' do
          expect { value }.to raise_error(
            ParseArgv::Error,
            'test: file attribute `symlink` not satisfied - <file>'
          )
        end
      end
    end
  end

  context ':directory' do
    let(:value) { result.as(:directory, :dir) }
    let(:argv) { ['--dir', __dir__] }

    it 'returns the correct value' do
      expect(value).to eq __dir__
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--dir invalid] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: directory does not exist - <dir>'
        )
      end
    end

    context 'when not a file is given' do
      let(:argv) { ['--dir', __FILE__] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument must be a directory - <dir>'
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
      let(:value) { result.as(:directory, :dir, :readable) }

      it 'returns the correct value' do
        expect(value).to eq __dir__
      end

      context 'when the attribute is not valid for the directory' do
        let(:value) { result.as(:directory, :dir, :symlink) }

        it 'raises an error' do
          expect { value }.to raise_error(
            ParseArgv::Error,
            'test: directory attribute `symlink` not satisfied - <dir>'
          )
        end
      end
    end
  end

  context ':array' do
    let(:value) { result.as(:array, :ary) }
    let(:argv) { ['--ary', '[aaaa,  bbb,cc  ,,d]'] }

    it 'returns the correct value' do
      expect(value).to eq %w[aaaa bbb cc d]
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--ary []] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument can not be empty - <ary>'
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

  context 'Given String Array' do
    let(:value) { result.as(%w[one two three], :item) }
    let(:argv) { %w[--item two] }

    it 'returns the correct value' do
      expect(value).to eq 'two'
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--item invalid] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument must be one of `one`, `two`, `three` - <item>'
        )
      end
    end

    context 'when value is not defined' do
      let(:argv) { [] }

      it 'returns nil' do
        expect(value).to be_nil
      end

      context 'when a default is specified' do
        let(:value) { result.as(%w[one two three], :item, default: 'seven') }

        it 'returns the default value' do
          expect(value).to eq 'seven'
        end
      end
    end
  end

  context 'Types Array' do
    let(:value) { result.as('array[positive]', :tary) }
    let(:argv) { %w[--tary [1,2,3]] }

    it 'returns the correct value' do
      expect(value).to eq [1, 2, 3]
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--tary [1,2,-3]] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: positive number expected - <tary>'
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

  context 'Given Regular Expression' do
    let(:value) { result.as(/\Ate+st\z/, :match) }
    let(:argv) { %w[--match teeeeest] }

    it 'returns the correct value' do
      expect(value).to eq 'teeeeest'
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--match toest] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument must match (?-mix:\Ate+st\z) - <match>'
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

  context 'custom types can be defined' do
    before do
      ParseArgv::Conversion.define(:my) do |arg, &err|
        arg == 'test' || err['not a custom type']
        arg
      end
    end

    let(:value) { result.as(:my, :custom) }
    let(:argv) { %w[--custom test] }

    it 'returns the correct value' do
      expect(value).to eq 'test'
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--custom invalid] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: not a custom type - <custom>'
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
