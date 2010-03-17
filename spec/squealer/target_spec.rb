require 'spec_helper'

describe Target do

  describe "#target" do

    let(:export_dbc) { nil }
    let(:table_name) { :test_table }
    let(:row_id) { 0 }
    let(:target) { Target.new(export_dbc, table_name, row_id) { nil } }

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
      target.sql.should =~ / VALUES \(#{row_id}\) /
    end

    it "yields inner blocks" do
      block_done = false
      target.target { block_done = true }
      block_done.should be_true
    end

    it "yields inner blocks first" do
      Target.new(export_dbc, table_name, row_id) { |target| target.sql.should be_empty }
    end

    it "yields inner blocks first and they can assign to this target" do
      target = Target.new(export_dbc, table_name, row_id) { |target| target.assign(:colA) { 42 } }
      target.sql.should =~ /colA/
      target.sql.should =~ /42/
    end

    context "with 2 columns" do

      let(:value_1) { 42 }
      let(:target) do
        Target.new(export_dbc, table_name, row_id) { |target| target.assign(:colA) { value_1 } }
      end

      it "includes the column name in the INSERT" do
        target.sql.should =~ /\(id,colA\) VALUES/
      end

      it "includes the column value in the INSERT" do
        target.sql.should =~ /VALUES \(#{row_id},'#{value_1}'\)/
      end

      it "includes the column name and value in the UPDATE" do
        target.sql.should =~ /UPDATE colA='#{value_1}'/
      end

    end

    context "with 3 columns" do

      let(:value_1) { 42 }
      let(:value_2) { 'foobar' }
      let(:target) do
        Target.new(export_dbc, table_name, row_id) do |target|
          target.assign(:colA) { value_1 }
          target.assign(:colB) { value_2 }
        end
      end

      it "includes the column names in the INSERT" do
        target.sql.should =~ /\(id,colA,colB\) VALUES/
      end

      it "includes the column values in the INSERT" do
        target.sql.should =~ /VALUES \(#{row_id},'#{value_1}','#{value_2}'\)/
      end

      it "includes the column names and values in the UPDATE" do
        target.sql.should =~ /UPDATE colA='#{value_1}',colB='#{value_2}'/
      end

    end

  end

end
