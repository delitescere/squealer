require 'spec_helper'

describe Object do

  it "has a target method" do
    Object.new.respond_to? :target
  end

  it "invokes Target.new" do
    Target.should_receive(:new)
    target(:test_table, 1) { nil }
  end

  it "uses the export database connection"

end
