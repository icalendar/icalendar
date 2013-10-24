require 'spec_helper'

describe Icalendar::Calendar do

  context 'properties' do
    let(:property) { 'my-value' }

    %w(prodid version calscale method x_custom_prop).each do |prop|
      it "##{prop} sets and gets" do
        subject.send("#{prop}=", property)
        subject.send(prop).should == property
      end
    end

    context "required properties" do
      it 'is not valid when prodid is not set' do
        subject.prodid = nil
        subject.should_not be_valid
      end

      it 'is not valid when version is not set' do
        subject.version = nil
        subject.should_not be_valid
      end

      it 'is valid when both prodid and version are set' do
        subject.version = '2.0'
        subject.prodid = 'my-product'
        subject.should be_valid
      end

      it 'is valid by default' do
        subject.should be_valid
      end
    end
  end

  context 'components' do
    let(:ical_component) { double 'Component', name: 'event', 'parent=' => nil }

    %w(event todo journal freebusy timezone).each do |component|
      it "##{component} adds a new component" do
        subject.send("#{component}").should be_a_kind_of Icalendar::Component
      end

      it "##{component} passes a component to a block to build parts" do
        expect { |b| subject.send("#{component}", &b) }.to yield_with_args Icalendar::Component
      end

      it "##{component} can be passed in" do
        expect { |b| subject.send("#{component}", ical_component, &b) }.to yield_with_args ical_component
        subject.send("#{component}", ical_component).should == ical_component
      end
    end

    it "adds event to events list" do
      subject.event ical_component
      subject.events.should == [ical_component]
    end

    describe '#add_event' do
      it 'delegates to non add_ version' do
        subject.should_receive(:event).with ical_component
        subject.add_event ical_component
      end
    end

    describe '#find_event' do
      let(:ical_component) { double 'Component', uid: 'uid' }
      let(:other_component) { double 'Component', uid: 'other' }
      before(:each) do
        subject.events << other_component
        subject.events << ical_component
      end

      it 'finds by uid' do
        subject.find_event('uid').should == ical_component
      end
    end

    it "adds reference to parent" do
      e = subject.event
      e.parent.should == subject
    end

    it 'can be added with add_x_ for custom components' do
      subject.add_x_custom_component.should be_a_kind_of Icalendar::Component
      expect { |b| subject.add_x_custom_component(&b) }.to yield_with_args Icalendar::Component
      subject.add_x_custom_component(ical_component).should == ical_component
    end
  end
end
