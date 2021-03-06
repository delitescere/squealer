require 'spec_helper'

describe NilClass do

  describe "#each" do
    it "returns an empty array" do
      nil.each.should == [] # because mongo is schema-less
    end
  end

  describe "#reject" do
    it "returns an empty array" do
      nil.reject{false}.should == [] # because mongo is schema-less
    end
  end

end

describe Object do
  let(:test_table) { {'_id' => 1} }

  describe "#target" do

    it "has been defined" do
      Object.new.respond_to?(:target).should be_true
    end

    it "invokes Squealer::Target.new" do
      Squealer::Target.should_receive(:new)
      target(:test_table) { nil }
    end

  end

  describe "#assign" do

    it "has been defined" do
      Object.new.respond_to?(:assign).should be_true
    end

    it "invokes assign on the target it is immediately nested within" do
      mock_mysql
      target(:test_table) do |target1|
        target1.should_receive(:assign)
        assign(:colA) { 42 }

        test_table_2 = test_table
        target(:test_table_2) do |target2|
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

    context "with a single argument" do

      it "invokes Database.import_from" do
        Squealer::Database.instance.should_receive(:import_from)
        import('test_import')
      end

    end

    context "with no argment" do

      it "invokes Database.import" do
        Squealer::Database.instance.should_receive(:import)
        import
      end

    end

  end

  describe "#export" do

    it "has been defined" do
      Object.new.respond_to?(:export).should be_true
    end

    context "with a single argument" do

      it "invokes Database.export_to" do
        Squealer::Database.instance.should_receive(:export_to)
        export('test_export')
      end

    end

    context "with no argment" do

      it "invokes Database.export" do
        Squealer::Database.instance.should_receive(:export)
        export
      end

    end

  end

  def mock_mysql
    require 'data_objects'

    my = mock(DataObjects::Connection)
    comm = mock(DataObjects::Command)
    Squealer::Database.instance.should_receive(:export).at_least(:once).and_return(my)
    my.should_receive(:create_command).at_least(:once).and_return(comm)
    comm.should_receive(:execute_non_query).at_least(:once)
  end

end
