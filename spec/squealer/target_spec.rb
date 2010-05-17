require 'spec_helper'

describe Squealer::Target do
  after(:each) do
    Squealer::Target::Queue.instance.clear
  end

  context "targeting" do
    let(:export_dbc) { mock(Mysql) }
    before(:each) do
      Squealer::Database.instance.should_receive(:export).at_least(:once).and_return(export_dbc)
      st = mock(Mysql::Stmt)
      export_dbc.should_receive(:prepare).at_least(:once).and_return(st)
      st.should_receive(:execute).at_least(:once)
    end

    describe "initialize" do
      let(:faqs) { [{'_id' => 123}] }

      context "without a target row id" do
        it "infers it from the variable with a name matching the target table name" do
          faqs.each do |faq|
            Squealer::Target.new(nil, :faq) do |target|
              target.send(:instance_variable_get, '@row_id').should == faq['_id']
            end
          end
        end
      end

      context "with a target row id" do
        it "uses the passed value" do
          faqs.each do |faq|
            Squealer::Target.new(nil, :faq, 1) do |target|
              target.send(:instance_variable_get, '@row_id').should == 1
            end
          end
        end
      end

    end
  end

  context "assigning" do
    let(:export_dbc) { mock(Mysql) }
    before(:each) do
      Squealer::Database.instance.should_receive(:export).at_least(:once).and_return(export_dbc)
      st = mock(Mysql::Stmt)
      export_dbc.should_receive(:prepare).at_least(:once).and_return(st)
      st.should_receive(:execute).at_least(:once)
    end
    after(:each) do
      Squealer::Target::Queue.instance.clear
    end

    describe "#assign" do
      let(:col1) { :meaning }
      let(:value1) { 42 }
      let(:faqs) { [{'_id' => nil, col1.to_s => value1}] }
      let(:askers) { [{'_id' => 2001, 'name' => 'Zarathustra'}] }

      context "with a block" do
        it "uses the value from the block" do
          faqs.each do |faq|
            Squealer::Target.new(nil, :faq) do
              assign(col1) { value1 }
              Squealer::Target.current.instance_variable_get('@column_names').should == [col1]
              Squealer::Target.current.instance_variable_get('@column_values').should == [value1]
            end
          end
        end
      end

      context "without a block" do
        it "throws an exception" do
          faqs.each do |faq|
            Squealer::Target.new(nil, :faq) do
              lambda { assign(col1) }.should raise_exception
            end
          end
        end
      end

      context "with an empty block" do
        it "infers source from target name" do
          faqs.each do |faq|
            Squealer::Target.new(nil, :faq) do
              assign(col1) {}
              Squealer::Target.current.instance_variable_get('@column_names').should == [col1]
              Squealer::Target.current.instance_variable_get('@column_values').should == [value1]
            end
          end
        end

        it "infers related source from target name" do
          askers.each do |asker|
            faqs.each do |faq|
              Squealer::Target.new(nil, :faq) do
                assign(:asker_id) {}
                Squealer::Target.current.instance_variable_get('@column_names').should == [:asker_id]
                Squealer::Target.current.instance_variable_get('@column_values').should == [2001]
              end
            end
          end
        end
      end
    end
  end

  context "exports" do
    let(:export_dbc) { mock(Mysql) }
    let(:table_name) { :test_table }
    let(:test_table) { {'_id' => 0} }

    before(:each) do
      Squealer::Database.instance.should_receive(:export).at_least(:once).and_return(export_dbc)
      st = mock(Mysql::Stmt)
      export_dbc.should_receive(:prepare).at_least(:once).and_return(st)
      st.should_receive(:execute).at_least(:once)
    end

    it "sends the sql to the export database" do
      Squealer::Target.new(export_dbc, table_name) { nil }
    end

    describe "#target" do

      it "pushes itself onto the targets stack when starting" do
        @target1 = nil
        @target2 = nil
        target1 = Squealer::Target.new(export_dbc, table_name) do
          @target1 = Squealer::Target.current
          test_table_2 = test_table
          Squealer::Target.new(export_dbc, "#{table_name}_2") do
            @target2 = Squealer::Target.current
            @target2.should_not == @target1
          end
        end
        target1.should === @target1
      end

      it "pops itself off the targets stack when finished" do
        Squealer::Target.new(export_dbc, table_name) { nil }
        Squealer::Target.current.should be_nil
      end

      context "generates SQL command strings" do

        let(:target) { Squealer::Target.new(export_dbc, table_name) { nil } }

        it "targets the table" do
          target.sql.should =~ /^INSERT #{table_name} /
        end

        it "uses an INSERT ... ON DUPLICATE KEY UPDATE statement" do
          target.sql.should =~ /^INSERT .* ON DUPLICATE KEY UPDATE /
        end

        it "includes the primary key name in the INSERT" do
          target.sql.should =~ / \(id\) VALUES/
        end

        it "includes the primary key value in the INSERT" do
          # target.sql.should =~ / VALUES \('#{row_id}'\) /
          target.sql.should =~ / VALUES \(\?\) /
        end

      end

      context "with inner block" do

        it "yields inner blocks" do
          block_done = false
          target = Squealer::Target.new(export_dbc, table_name) { block_done = true }
          block_done.should be_true
        end

        it "yields inner blocks first" do
          Squealer::Target.new(export_dbc, table_name) { Squealer::Target.current.sql.should be_empty }
        end

        it "yields inner blocks first and they can assign to this target" do
          target = Squealer::Target.new(export_dbc, table_name) { Squealer::Target.current.assign(:colA) { 42 } }
          target.sql.should =~ /colA/
          # target.sql.should =~ /42/
          target.sql.should =~ /\?/
        end

        context "with 2 columns" do

          let(:value_1) { 42 }
          let(:target) do
            Squealer::Target.new(export_dbc, table_name) { Squealer::Target.current.assign(:colA) { value_1 } }
          end

          it "includes the column name in the INSERT" do
            target.sql.should =~ /\(id,colA\) VALUES/
          end

          it "includes the column value in the INSERT" do
            # target.sql.should =~ /VALUES \('#{row_id}','#{value_1}'\)/
            target.sql.should =~ /VALUES \(\?,\?\)/
          end

          it "includes the column name and value in the UPDATE" do
            # target.sql.should =~ /UPDATE colA='#{value_1}'/
            target.sql.should =~ /UPDATE colA=\?/
          end

        end

        context "with 3 columns" do

          let(:value_1) { 42 }
          let(:value_2) { 'foobar' }
          let(:target) do
            Squealer::Target.new(export_dbc, table_name) do
              Squealer::Target.current.assign(:colA) { value_1 }
              Squealer::Target.current.assign(:colB) { value_2 }
            end
          end

          it "includes the column names in the INSERT" do
            target.sql.should =~ /\(id,colA,colB\) VALUES/
          end

          it "includes the column values in the INSERT" do
            # target.sql.should =~ /VALUES \('#{row_id}','#{value_1}','#{value_2}'\)/
            target.sql.should =~ /VALUES \(\?,\?,\?\)/
          end

          it "includes the column names and values in the UPDATE" do
            # target.sql.should =~ /UPDATE colA='#{value_1}',colB='#{value_2}'/
            target.sql.should =~ /UPDATE colA=\?,colB=\?/
          end
        end
      end
    end
  end
end
