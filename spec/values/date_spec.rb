require 'spec_helper'

describe Icalendar::Values::Date do

  subject { described_class.new value, params }
  let(:value) { '20140209' }
  let(:params) { {} }

  describe "#==" do
    let(:other) { described_class.new value }

    it "is equivalent to another Icalendar::Values::Date" do
      expect(subject).to eq other
    end

    context "differing params" do
      let(:params) { {"x-custom-param": "param-value"} }

      it "is no longer equivalent" do
        expect(subject).not_to eq other
      end
    end
  end
end
