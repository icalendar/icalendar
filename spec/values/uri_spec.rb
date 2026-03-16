require 'spec_helper'

describe Icalendar::Values::Uri do
  describe '#value_ical' do
    it 'percent-encodes CRLF to prevent content-line injection' do
      value = described_class.new("https://a.example/ok\r\nATTENDEE:mailto:evil@example.com")

      expect(value.value_ical).to eq('https://a.example/ok%0D%0AATTENDEE:mailto:evil@example.com')
    end

    it 'percent-encodes the full ASCII control range' do
      raw = "https://example.com/a\tb\f#{0.chr}#{127.chr}"
      value = described_class.new(raw)

      expect(value.value_ical).to eq('https://example.com/a%09b%0C%00%7F')
    end

    it 'leaves valid printable URI characters unchanged' do
      raw = 'https://example.com/a-path?q=one%20two&x=@tag#frag'
      value = described_class.new(raw)

      expect(value.value_ical).to eq(raw)
    end
  end

  describe '#to_ical' do
    it 'serializes injected CRLF on the same content line' do
      value = described_class.new("https://a.example/ok\r\nATTENDEE:mailto:evil@example.com")

      expect(value.to_ical(Icalendar::Values::Text)).to eq(
        ';VALUE=URI:https://a.example/ok%0D%0AATTENDEE:mailto:evil@example.com'
      )
    end
  end
end

describe Icalendar::Values::CalAddress do
  it 'inherits URI control-byte encoding' do
    value = described_class.new("mailto:user@example.com\r\nORGANIZER:mailto:evil@example.com")

    expect(value.value_ical).to eq('mailto:user@example.com%0D%0AORGANIZER:mailto:evil@example.com')
  end
end
