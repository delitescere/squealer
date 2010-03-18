require 'spec_helper'

describe Time do

  describe "#to_s" do
    it "uses a MySQL compliant format" do
      Time.gm(2000,"Jan",31).to_s.should == "2000-01-31 00:00:00 UTC"
    end
  end
end
