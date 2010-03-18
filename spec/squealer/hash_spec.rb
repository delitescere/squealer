require "spec_helper"

describe Hash do

  describe "#method_missing" do

    it "treats it as a hash key lookup" do
      { "name" => "Josh" }.name.should == "Josh"
    end

    context "with args" do

      it "treats it normally" do
        lambda { { "name" => "Josh" }.name(nil) }.should raise_error(NoMethodError)
      end

    end

    context "with block" do

      it "treats it normally" do
        lambda { { "name" => "Josh" }.name {nil} }.should raise_error(NoMethodError)
      end

    end

  end
end
