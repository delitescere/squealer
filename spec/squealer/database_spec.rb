require 'spec_helper'

describe Database do

  it "is a singleton" do
    Database.respond_to?(:instance).should be_true
  end

  it "takes an import database" do
    Database.instance.import = 'import_database'
    Database.instance.import.should == 'import_database'
  end

  it "takes an export database" do
    Database.instance.export = 'export_database'
    Database.instance.export.should == 'export_database'
  end

end
