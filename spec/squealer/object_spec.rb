require 'spec_helper'

describe NilClass do

  describe "#each" do
    it "returns an empty array" do
      nil.each.should == []
    end
  end
end

describe Object do

  describe "#target" do

    it "has been defined" do
      Object.new.respond_to?(:target).should be_true
    end

    it "invokes Squealer::Target.new" do
      Squealer::Target.should_receive(:new)
      target(:test_table, 1) { nil }
    end

    it "uses the export database connection" do
      mock_mysql
      target(:test_table, 1) { nil }
    end

  end

  describe "#assign" do

    it "has been defined" do
      Object.new.respond_to?(:assign).should be_true
    end

    it "invokes assign on the target it is immediately nested within" do
      mock_mysql
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
      Squealer::Database.instance.should_receive(:import=)
      import('test_import')
    end

  end

  describe "#export" do

    it "has been defined" do
      Object.new.respond_to?(:export).should be_true
    end

    it "invokes Database.export=" do
      Squealer::Database.instance.should_receive(:export=)
      export('test_export')
    end

  end

  def mock_mysql
    my = mock(Mysql)
    st = mock(Mysql::Stmt)
    Squealer::Database.instance.should_receive(:export).at_least(:once).and_return(my)
    my.should_receive(:prepare).at_least(:once).and_return(st)
    st.should_receive(:execute).at_least(:once)
  end

end
