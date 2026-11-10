require 'spec_helper'
require_relative '../lib/icalendar/tzinfo'

describe Icalendar::TransitionRuleSample do
  def sample_transition(year, month, day = nil)
    day ||= (2..8).find { |value| Date.new(year, month, value).wday == 0 }
    from, to = month == 4 ? [-10800, -14400] : [-14400, -10800]
    offset_type = Struct.new(:utc_total_offset)
    transition_type = Struct.new(:local_end, :previous_offset, :offset) do
      include Icalendar::TimezoneTransition
    end
    transition_type.new(DateTime.new(year, month, day), offset_type.new(from), offset_type.new(to))
  end

  let(:transitions) { (2026...2054).flat_map { |year| [sample_transition(year, 4), sample_transition(year, 9)] } }
  let(:anchors) { transitions.first(2) }

  def inferred(items = transitions, references = anchors, years = 28)
    described_class.rules(items, references, 2026, years)
  end

  it 'infers each complete same-month seven-day window' do
    expect(inferred).to eq([
      ['FREQ=YEARLY;BYMONTH=4;BYDAY=SU;BYMONTHDAY=2,3,4,5,6,7,8'],
      ['FREQ=YEARLY;BYMONTH=9;BYDAY=SU;BYMONTHDAY=2,3,4,5,6,7,8']
    ])
  end

  it 'preserves a validated ordinary ordinal rule' do
    ordinary = (2026...2054).flat_map do |year|
      [4, 9].map do |month|
        day = (1..7).find { |value| Date.new(year, month, value).wday == 0 }
        sample_transition(year, month, day)
      end
    end
    expect(inferred(ordinary, ordinary.first(2))).to eq(ordinary.first(2).map(&:rrule))
  end

  it 'rejects a missing transition' do
    expect(inferred(transitions[1..-1])).to be_nil
  end

  it 'rejects a missing complete year' do
    expect(inferred(transitions.reject { |item| item.local_end.year == 2032 })).to be_nil
  end

  it 'rejects additional transitions even when they have unrelated offsets' do
    extra = sample_transition(2032, 4)
    extra.offset.utc_total_offset = -12000
    expect(inferred(transitions + [extra])).to be_nil
  end

  it 'rejects a one-second change in local onset' do
    transitions[10].local_end += Rational(1, 86400)
    expect(inferred).to be_nil
  end

  it 'rejects a sub-minute offset change without using formatted offsets' do
    transitions[10].offset.utc_total_offset += 1
    expect(inferred).to be_nil
  end

  it 'rejects a transition crossing into another month' do
    transitions[10].local_end = DateTime.new(2031, 3, 30)
    expect(inferred).to be_nil
  end

  it 'rejects an exceptional year despite unchanged weekday and offsets' do
    transitions[10].local_end += 7
    expect(inferred).to be_nil
  end

  it 'rejects incomplete seven-day coverage rather than guessing from extrema' do
    expect(inferred(transitions.first(8), anchors, 4)).to be_nil
  end

  it 'rejects fractional onset seconds' do
    transitions[10].local_end += Rational(1, 172800)
    expect(inferred).to be_nil
  end
end
