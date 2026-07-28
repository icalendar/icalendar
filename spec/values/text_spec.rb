require 'spec_helper'

describe Icalendar::Values::Text do

  subject { described_class.new value }
  let(:unescaped) { "This \\ that, semi; colons\r\nAnother line: \"why not?\"" }
  let(:escaped) { 'This \\\\ that\, semi\; colons\nAnother line: "why not?"' }

  describe '#value_ical' do
    let(:value) { unescaped }
    it 'escapes \ , ; NL' do
      expect(subject.value_ical).to eq escaped
    end
  end

  describe 'unescapes in initializer' do
    context 'given escaped version' do
      let(:unescaped_no_cr) { unescaped.gsub "\r", '' }
      let(:value) { escaped }
      it 'removes escaping' do
        expect(subject.value).to eq unescaped_no_cr
      end
    end

    context 'given unescaped version' do
      let(:value) { unescaped }
      it 'does not try to double unescape' do
        expect(subject.value).to eq unescaped
      end
    end
  end

  describe 'unescape is the exact inverse of value_ical' do
    bs = "\\"
    {
      'a literal backslash before n (windows path)' => ["C:#{bs}#{bs}next", "C:#{bs}next"],
      'a UNC path with several backslashes'         => ["#{bs * 4}srv#{bs * 2}sh", "#{bs * 2}srv#{bs}sh"],
      'an escaped backslash alone'                  => ["a#{bs}#{bs}b", "a#{bs}b"],
      'an escaped comma'                            => ["a#{bs},b", 'a,b'],
      'an escaped semicolon'                        => ["a#{bs};b", 'a;b'],
      'a lowercase newline escape'                  => ["a#{bs}nb", "a\nb"],
      'plain text without backslashes'              => ['plain summary text', 'plain summary text'],
    }.each do |desc, (onwire, content)|
      context "given #{desc}" do
        subject { described_class.new onwire.dup }

        it 'decodes to the original content' do
          expect(subject.value).to eq content
        end

        it 'round-trips back to the on-wire form' do
          expect(subject.value_ical).to eq onwire
        end
      end
    end

    it 'decodes a capital-N newline escape (RFC 5545 3.3.11)' do
      expect(described_class.new("a#{bs}Nb").value).to eq "a\nb"
    end

    it 'leaves a backslash before a non-escape char untouched' do
      expect(described_class.new("a#{bs}:b").value).to eq "a#{bs}:b"
    end
  end

  describe 'escapes parameter text properly' do
    subject { described_class.new escaped, {'param' => param_value} }
    context 'single value, no special characters' do
      let(:param_value) { 'HelloWorld' }
      it 'does not wrap param in double quotes' do
        expect(subject.params_ical).to eq %(;PARAM=HelloWorld)
      end
    end
    context 'single value, special characters' do
      let(:param_value) { 'Hello:World' }
      it 'wraps param value in double quotes' do
        expect(subject.params_ical).to eq %(;PARAM="Hello:World")
      end
    end
    context 'single value, double quotes' do
      let(:param_value) { 'Hello "World"' }
      it 'replaces double quotes with single' do
        expect(subject.params_ical).to eq %(;PARAM=Hello 'World')
      end
    end
    context 'multiple values, no special characters' do
      let(:param_value) { ['HelloWorld', 'GoodbyeMoon'] }
      it 'joins with comma' do
        expect(subject.params_ical).to eq %(;PARAM=HelloWorld,GoodbyeMoon)
      end
    end
    context 'multiple values, with special characters' do
      let(:param_value) { ['Hello, World', 'GoodbyeMoon'] }
      it 'quotes values with special characters, joins with comma' do
        expect(subject.params_ical).to eq %(;PARAM="Hello, World",GoodbyeMoon)
      end
    end
    context 'multiple values, double quotes' do
      let(:param_value) { ['Hello, "World"', 'GoodbyeMoon'] }
      it 'replaces double quotes with single' do
        expect(subject.params_ical).to eq %(;PARAM="Hello, 'World'",GoodbyeMoon)
      end
    end
    context 'nil value' do
      let(:param_value) { nil }
      it 'trats nil as blank' do
        expect(subject.params_ical).to eq %(;PARAM=)
      end
    end
  end
end
