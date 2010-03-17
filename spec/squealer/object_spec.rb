require 'spec_helper'

describe Object do

  describe "#target" do

    it "has been defined" do
      Object.new.respond_to?(:target).should be_true
    end

    it "invokes Target.new" do
      Target.should_receive(:new)
      target(:test_table, 1) { nil }
    end

    it "uses the export database connection" do
      Database.instance.should_receive(:export)
      target(:test_table, 1) { nil }
    end

  end

  describe "#assign" do

    it "has been defined" do
      Object.new.respond_to?(:assign).should be_true
    end

    it "invokes assign on the target it is immediately nested within" do
      target(:test_table, 1) do |target1|
        target1.should_receive(:assign)
        assign(:colA) { 42 }

        target(:test_table_2, 1) do |target2|
          target2.should_receive(:assign)
          assign(:colspeak) { 1984 }
        end
      end
    end

  end

  describe "#import" do

    it "has been defined" do
      Object.new.respond_to?(:import).should be_true
    end

    it "invokes Database.import=" do
      Database.instance.should_receive(:import=)
      import('test_import')
    end

  end

  describe "#export" do

    it "has been defined" do
      Object.new.respond_to?(:export).should be_true
    end

    it "invokes Database.export=" do
      Database.instance.should_receive(:export=)
      export('test_export')
    end

  end

end
