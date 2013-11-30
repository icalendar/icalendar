require 'spec_helper'

describe Icalendar::Values::Text do

  subject { described_class.new "This \\ that, semi; colons\r\nAnother line: \"why not?\"" }

  describe '#value_ical' do
    it 'escapes \ , ; NL' do
      expect(subject.value_ical).to eq 'This \\\\ that\, semi\; colons\nAnother line: "why not?"'
    end
  end
end
