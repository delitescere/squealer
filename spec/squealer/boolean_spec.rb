require "spec_helper"

describe TrueClass do

  describe "#to_i" do

    it "returns 1" do
      true.to_i.should == 1
    end
  end
end

describe FalseClass do

  it "returns 0" do
    false.to_i.should == 0
  end
end
