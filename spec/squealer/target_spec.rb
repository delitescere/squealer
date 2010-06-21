require 'spec_helper'

describe Squealer::Target do
  let(:table_name) { :test_table }
  let(:test_table) { {'_id' => 0} }

  let(:export_dbc) { mock(Mysql) }

  after(:each) { Squealer::Target::Queue.instance.clear }


  context "targeting" do
    describe "initialize" do
      let(:faqs) { [{'_id' => '123'}] }

      context "without a target row id" do
        context "with the inferred variable in scope" do
          it "infers the value from the _id field in the hashmap referenced by the variable" do
            mock_mysql

            faqs.each do |faq|
              Squealer::Target.new(nil, :faq) do |target|
                target.send(:instance_variable_get, '@row_id').should == faq['_id']
              end
            end
          end

          context "but it doesn't have an _id key" do
            it "throws an argument error" do
              hash_with_no_id = {}
              lambda do
                Squealer::Target.new(nil, :hash_with_no_id) {}
              end.should raise_error(ArgumentError)
            end
          end

          context "but it isn't a hashmap" do
            it "throws an argument error" do
              not_a_hash = nil
              lambda do
                Squealer::Target.new(nil, :not_a_hash) {}
              end.should raise_error(ArgumentError)
            end
          end
        end

        context "without the inferred variable in scope" do
          it "throws a name error" do
            lambda do
              Squealer::Target.new(nil, :missing_variable) {}
            end.should raise_error(NameError)
          end
        end
      end

      context "with a target row id" do
        it "uses the passed value" do
          mock_mysql

          faqs.each do |faq|
            Squealer::Target.new(nil, :faq, 1) do |target|
              target.send(:instance_variable_get, '@row_id').should == 1
            end
          end
        end
      end
    end
  end


  context "nesting" do
    it "pushes itself onto the targets stack when starting" do
      mock_mysql
      @target1 = @target2 = nil

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
      mock_mysql

      Squealer::Target.new(export_dbc, table_name) { nil }
      Squealer::Target.current.should be_nil
    end
  end


  context "yielding" do
    it "yields" do
      mock_mysql

      block_done = false
      target = Squealer::Target.new(export_dbc, table_name) { block_done = true }
      block_done.should be_true
    end

    it "yields inner blocks before executing its own SQL" do
      mock_mysql

      blocks_done = []
      Squealer::Target.new(export_dbc, table_name) do |target_1|
        blocks_done << target_1
        blocks_done.first.sql.should be_empty
        Squealer::Target.new(export_dbc, table_name) do |target_2|
          blocks_done << target_2
          blocks_done.first.sql.should be_empty
          blocks_done.last.sql.should be_empty
        end
        blocks_done.first.sql.should be_empty
        blocks_done.last.sql.should_not be_empty
      end
      blocks_done.first.sql.should_not be_empty
      blocks_done.last.sql.should_not be_empty
    end
  end


  context "assigning" do
    describe "#assign" do
      let(:col1) { :meaning }
      let(:value1) { 42 }
      let(:faqs) { [{'_id' => nil, col1.to_s => value1}] }
      let(:askers) { [{'_id' => 2001, 'name' => 'Zarathustra'}] }

      context "with a block" do
        it "uses the value from the block" do
          mock_mysql

          faqs.each do |faq|
            Squealer::Target.new(nil, :faq) do
              assign(col1) { value1 }
              Squealer::Target.current.instance_variable_get('@column_names').should == [col1]
              Squealer::Target.current.instance_variable_get('@column_values').should == [value1]
            end
          end
        end
        it "uses the value from the block even if it is nil" do
          mock_mysql

          faqs.each do |faq|
            Squealer::Target.new(nil, :faq) do
              assign(col1) { nil }
              Squealer::Target.current.instance_variable_get('@column_names').should == [col1]
              Squealer::Target.current.instance_variable_get('@column_values').should == [nil]
            end
          end
        end
      end

      context "without a block" do
        context "with the inferred variable in scope" do
          it "infers source from target name" do
            mock_mysql

            faqs.each do |faq|
              Squealer::Target.new(nil, :faq) do
                assign(col1)
                Squealer::Target.current.instance_variable_get('@column_names').should == [col1]
                Squealer::Target.current.instance_variable_get('@column_values').should == [value1]
              end
            end
          end
          it "infers related source from target name" do
            mock_mysql

            askers.each do |asker|
              faqs.each do |faq|
                Squealer::Target.new(nil, :faq) do
                  assign(:asker_id)
                  Squealer::Target.current.instance_variable_get('@column_names').should == [:asker_id]
                  Squealer::Target.current.instance_variable_get('@column_values').should == [2001]
                end
              end
            end
          end
        end
      end

      context "with an empty block" do
        it "assumes nil" do
          mock_mysql

          faqs.each do |faq|
            Squealer::Target.new(nil, :faq) do
              assign(col1) {}
              Squealer::Target.current.instance_variable_get('@column_names').should == [col1]
              Squealer::Target.current.instance_variable_get('@column_values').should == [nil]
            end
          end
        end
      end
    end
  end


  context "exporting" do
    before(:each) { mock_mysql }

    it "sends the sql to the export database" do
      Squealer::Target.new(export_dbc, table_name) { nil }
    end

    describe "#target" do
      describe "#typecast_values" do
        subject { target.send(:typecast_values) }
        let(:target) { Squealer::Target.new(export_dbc, table_name) {} }

        it "casts array to comma-separated string" do
          target.assign(:colA) { ['1', '2'] }
          subject.should == ['1,2']
        end
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

      context "with 2 columns" do
        let(:value_1) { 42 }
        let(:target) do
          Squealer::Target.new(export_dbc, table_name) { Squealer::Target.current.assign(:colA) { value_1 } }
        end

        it "includes the column name in the INSERT" do
          target.sql.should =~ /\(id,`colA`\) VALUES/
        end

        it "includes the column value in the INSERT" do
          # target.sql.should =~ /VALUES \('#{row_id}','#{value_1}'\)/
          target.sql.should =~ /VALUES \(\?,\?\)/
        end

        it "includes the column name and value in the UPDATE" do
          # target.sql.should =~ /UPDATE colA='#{value_1}'/
          target.sql.should =~ /UPDATE `colA`=\?/
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
          target.sql.should =~ /\(id,`colA`,`colB`\) VALUES/
        end

        it "includes the column values in the INSERT" do
          # target.sql.should =~ /VALUES \('#{row_id}','#{value_1}','#{value_2}'\)/
          target.sql.should =~ /VALUES \(\?,\?,\?\)/
        end

        it "includes the column names and values in the UPDATE" do
          # target.sql.should =~ /UPDATE colA='#{value_1}',colB='#{value_2}'/
          target.sql.should =~ /UPDATE `colA`=\?,`colB`=\?/
        end
      end
    end
  end
end

def mock_mysql
  my = mock(DataObjects::Connection)
  comm = mock(DataObjects::Command)
  Squealer::Database.instance.should_receive(:export).at_least(:once).and_return(my)
  my.should_receive(:create_command).at_least(:once).and_return(comm)
  comm.should_receive(:execute_non_query).at_least(:once)
end
