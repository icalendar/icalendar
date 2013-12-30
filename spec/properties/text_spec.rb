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

  describe 'unescape initializer' do
    let(:value) { escaped }

    it 'saves unescaped version' do
      expect(subject.value).to eq escaped
    end
  end
end
