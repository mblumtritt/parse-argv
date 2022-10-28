# frozen_string_literal: true

require_relative '../helper'

RSpec.describe 'parse arguments' do
  context 'when all arguments are required' do
    let(:help_text) { 'usage: test <file1> <file2>' }

    it 'accepts all parameters' do
      result = ParseArgv.from(help_text, %w[arg1 arg2])
      expect(result.file1).to eq 'arg1'
      expect(result.file2).to eq 'arg2'
    end

    it 'requires correct parameter count' do
      expect { ParseArgv.from(help_text, %w[arg1]) }.to raise_error(
        ParseArgv::Error,
        'test: argument missing - <file2>'
      )
      expect { ParseArgv.from(help_text, %w[arg1 arg2 arg3]) }.to raise_error(
        ParseArgv::Error,
        'test: too many arguments'
      )
    end
  end

  context 'when some arguments are optional' do
    let(:help_text) { 'usage: test <file1> [<file2>] <file3>' }

    it 'accepts all parameters' do
      result = ParseArgv.from(help_text, %w[arg1 arg2 arg3])
      expect(result.file1).to eq 'arg1'
      expect(result.file2).to eq 'arg2'
      expect(result.file3).to eq 'arg3'
    end

    it 'accepts minimum parameters' do
      result = ParseArgv.from(help_text, %w[arg1 arg3])
      expect(result.file1).to eq 'arg1'
      expect(result.member?(:file2)).to be false
      expect(result.file3).to eq 'arg3'
    end

    it 'requires correct parameter count' do
      expect { ParseArgv.from(help_text, %w[arg1]) }.to raise_error(
        ParseArgv::Error,
        'test: argument missing - <file3>'
      )
      expect { ParseArgv.from(help_text, %w[a1 a2 a3 a4]) }.to raise_error(
        ParseArgv::Error,
        'test: too many arguments'
      )
    end
  end

  context 'when additional arguments are required' do
    let(:help_text) { 'usage: test <file1> <files>...' }

    it 'accepts all given arguments' do
      result = ParseArgv.from(help_text, %w[arg1 arg2 arg3])
      expect(result.file1).to eq 'arg1'
      expect(result.files).to eq %w[arg2 arg3]
    end

    it 'requires additional arguments' do
      expect { ParseArgv.from(help_text, %w[arg1]) }.to raise_error(
        ParseArgv::Error,
        'test: argument missing - <files>'
      )
    end
  end

  context 'when additional arguments are optional' do
    let(:help_text) { 'usage: test <file1> [<files>...]' }

    it 'accepts all given arguments' do
      result = ParseArgv.from(help_text, %w[arg1 arg2 arg3])
      expect(result.file1).to eq 'arg1'
      expect(result.files).to eq %w[arg2 arg3]
    end

    it 'does not require additional parameters' do
      result = ParseArgv.from(help_text, %w[arg1])
      expect(result.file1).to eq 'arg1'
      expect(result.member?(:files)).to be false
    end
  end

  context 'when an argument name is already used' do
    let(:help_text) { 'usage: test <file1> [<file1>]' }

    it 'raises an error' do
      expect { ParseArgv.from(help_text, []) }.to raise_error(
        ArgumentError,
        'argument already defined - file1'
      )
    end
  end
end
