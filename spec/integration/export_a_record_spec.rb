require 'spec_helper'

describe "Exporting" do
  before do
    truncate_export_tables
  end

  let(:databases) { Squealer::Database.instance }

  def prepare_export_database
    databases.export_to('localhost', 'root', '', $db_name)
  end

  def squeal_basic_users_document(user=users_document)
    target(:user) do
      assign(:name)
      assign(:organization_id)
      assign(:dob)
      assign(:gender)
      assign(:awesome)
      assign(:fat)
      assign(:symbolic)
      assign(:interests)
    end
  end

  let :users_document do
    { :_id => 'ABCDEFGHIJKLMNOPQRSTUVWX',
      'name' => 'Test User', 'dob' => as_time(Date.parse('04-Jul-1776')), 'gender' => 'M',
      'awesome' => true,
      'fat' => false,
      'symbolic' => :of_course,
      'interests' => ['health', 'education'],
      'organization_id' => '123456789012345678901234',
      'activities' => [
        { 'name' => 'Be independent', 'due_date' => as_time(Date.today + 1) },
        { 'name' => 'Fight each other', 'due_date' => as_time(Date.today + 7) }
      ]
    }
  end

  let :first_users_record do
    dbc = databases.instance_variable_get('@export_do')
    reader = dbc.create_command('SELECT * FROM user').execute_reader
    reader.each { |x| break x }
  end

  context "a new record" do
    it "saves the data correctly" do
      prepare_export_database
      squeal_basic_users_document
      result = first_users_record

      result['name'].should == 'Test User'

      result['dob'].mday.should == 4
      result['dob'].mon.should == 7
      result['dob'].year.should == 1776

      result['gender'].should == 'M'

      result['awesome'].should be_true
      result['fat'].should be_false

      result['symbolic'].should == :of_course.to_s

      result['interests'].should == 'health,education'
    end
  end

  context "an existing record" do
    it "updates the data correctly" do
      prepare_export_database
      squeal_basic_users_document
      squeal_basic_users_document(users_document.merge('awesome' => false, 'gender' => 'F'))

      result = first_users_record

      result['name'].should == 'Test User'

      result['dob'].mday.should == 4
      result['dob'].mon.should == 7
      result['dob'].year.should == 1776

      result['gender'].should == 'F'

      result['awesome'].should be_false
      result['fat'].should be_false

      result['symbolic'].should == :of_course.to_s

      result['interests'].should == 'health,education'
    end
  end
end
