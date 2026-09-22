require 'spec_helper'
require_relative '../lib/icalendar/tzinfo'

describe 'TZInfo::Timezone' do

  let(:tz) { TZInfo::Timezone.get 'Europe/Copenhagen' }
  let(:date) { DateTime.new 2014 }
  subject { tz.ical_timezone date }

  describe 'daylight offset' do
    specify { expect(subject.daylights.first.tzoffsetto.value_ical).to eq "+0200" }
    specify { expect(subject.daylights.first.tzoffsetfrom.value_ical).to eq "+0100" }
  end

  describe 'standard offset' do
    specify { expect(subject.standards.first.tzoffsetto.value_ical).to eq "+0100" }
    specify { expect(subject.standards.first.tzoffsetfrom.value_ical).to eq "+0200" }
  end

  describe 'daylight recurrence rule' do
    specify { expect(subject.daylights.first.rrule.first.value_ical).to eq "FREQ=YEARLY;BYDAY=-1SU;BYMONTH=3" }
  end

  describe 'standard recurrence rule' do
    specify { expect(subject.standards.first.rrule.first.value_ical).to eq "FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10" }
  end

  describe 'transition onset' do
    let(:date) { DateTime.new 2021, 7, 1 }

    {
      'Europe/Stockholm' => {
        daylight: ['20210328T020000', '+0100', '20210328T010000Z'],
        standard: ['20211031T030000', '+0200', '20211031T010000Z']
      },
      'Australia/Lord_Howe' => {
        daylight: ['20211003T020000', '+1030', '20211002T153000Z'],
        standard: ['20210404T020000', '+1100', '20210403T150000Z']
      }
    }.each do |identifier, transitions|
      context identifier do
        let(:tz) { TZInfo::Timezone.get identifier }

        transitions.each do |kind, (local, offset, utc)|
          it "serializes the #{kind} onset using the previous offset" do
            calendar = Icalendar::Calendar.new
            calendar.add_timezone subject
            parsed = Icalendar::Calendar.parse(calendar.to_ical).first.timezones.first
            component = parsed.public_send("#{kind}s").first

            expect(component.dtstart.value_ical).to eq local
            expect(component.tzoffsetfrom.value_ical).to eq offset
            onset = DateTime.strptime("#{component.dtstart.value_ical}#{offset}", '%Y%m%dT%H%M%S%z')
            expect(onset.new_offset(0).strftime('%Y%m%dT%H%M%SZ')).to eq utc
          end
        end
      end
    end

    context 'when the clock change crosses midnight' do
      let(:tz) { TZInfo::Timezone.get 'America/Santiago' }

      it 'uses the previous-offset date for both DTSTART and the recurrence rule' do
        standard = subject.standards.first
        expect(standard.dtstart.value_ical).to eq '20210404T000000'
        expect(standard.rrule.first.value_ical).to eq 'FREQ=YEARLY;BYDAY=1SU;BYMONTH=4'
      end
    end
  end

  describe 'no end transition' do
    let(:tz) { TZInfo::Timezone.get 'Asia/Shanghai' }
    let(:date) { DateTime.now }

    it 'only creates a standard component' do
      expect(subject.to_ical).to eq <<-EXPECTED.gsub "\n", "\r\n"
BEGIN:VTIMEZONE
TZID:Asia/Shanghai
BEGIN:STANDARD
DTSTART:19910915T020000
TZOFFSETFROM:+0900
TZOFFSETTO:+0800
TZNAME:CST
END:STANDARD
END:VTIMEZONE
      EXPECTED
    end
  end

  describe 'no transition' do
    let(:tz) { TZInfo::Timezone.get 'UTC' }
    let(:date) { DateTime.now }

    it 'creates a standard component with equal offsets' do
      expect(subject.to_ical).to eq <<-EXPECTED.gsub "\n", "\r\n"
BEGIN:VTIMEZONE
TZID:UTC
BEGIN:STANDARD
DTSTART:19700101T000000
TZOFFSETFROM:+0000
TZOFFSETTO:+0000
TZNAME:UTC
END:STANDARD
END:VTIMEZONE
      EXPECTED
    end
  end

  describe 'dst transition' do
    subject { TZInfo::Timezone.get 'America/Los_Angeles' }
    let(:now) { subject.now }
    # freeze in DST transition in America/Los_Angeles
    before(:each) { Timecop.freeze DateTime.new(2013, 11, 03, 1, 30, 0, '-08:00') }
    after(:each) { Timecop.return }

    specify { expect { subject.ical_timezone now, nil }.to raise_error TZInfo::AmbiguousTime }
    specify { expect { subject.ical_timezone now, true }.not_to raise_error }
    specify { expect { subject.ical_timezone now, false }.not_to raise_error }

    context 'TZInfo::Timezone.default_dst = nil' do
      before(:each) { TZInfo::Timezone.default_dst = nil }
      specify { expect { subject.ical_timezone now }.to raise_error TZInfo::AmbiguousTime }
    end

    context 'TZInfo::Timezone.default_dst = true' do
      before(:each) { TZInfo::Timezone.default_dst = true }
      specify { expect { subject.ical_timezone now }.not_to raise_error }
    end

    context 'TZInfo::Timezone.default_dst = false' do
      before(:each) { TZInfo::Timezone.default_dst = false }
      specify { expect { subject.ical_timezone now }.not_to raise_error }
    end
  end

  describe 'tzname for offset' do
    # Check for CET/CEST correctness, which doesn't follow
    # the more common *ST/*DT style abbreviations.
    let(:tz) { TZInfo::Timezone.get 'Europe/Prague' }
    let(:ical_tz) { tz.ical_timezone date }

    describe '#daylight' do
      subject(:tzname) { ical_tz.daylights.first.tzname.first }
      it { should eql 'CEST' }
    end

    describe '#standard' do
      subject(:tzname) { ical_tz.standards.first.tzname.first }
      it { should eql 'CET' }
    end
  end

end
