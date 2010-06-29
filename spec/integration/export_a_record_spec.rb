require File.expand_path(File.dirname(__FILE__) + '/./spec_helper_dbms')

describe "Exporting" do
  let(:databases) { Squealer::Database.instance }
  let(:today) { Date.today }

  def squeal_basic_users_document(user=users_document)
    target(:user) do
      assign(:name)
      assign(:organization_id)
      assign(:dob)
      assign(:gender)
      assign(:foreign)
      assign(:dull)
      assign(:symbolic)
      assign(:interests)
    end
  end

  def squeal_users_document_with_activities(user=users_document)
    target(:user) do
      assign(:name)
      assign(:organization_id)
      assign(:dob)
      assign(:gender)
      assign(:foreign)
      assign(:dull)
      assign(:symbolic)
      assign(:interests)

      user.activities.each do |activity|
        target(:activity) do
          assign(:name)
          assign(:due_date)
        end
      end
    end
  end

  let :users_document do
    { :_id => 'ABCDEFGHIJKLMNOPQRSTUVWX',
      'name' => 'Test User', 'dob' => as_time(Date.parse('04-Jul-1776')), 'gender' => 'M',
      'foreign' => true,
      'dull' => false,
      'symbolic' => :of_course,
      'interests' => ['health', 'education'],
      'organization_id' => '123456789012345678901234',
      'activities' => [
        { :_id => 'a1', 'name' => 'Be independent', 'due_date' => as_time(today + 1) },
        { :_id => 'a2', 'name' => 'Fight each other', 'due_date' => as_time(today + 7) }
      ]
    }
  end

  let :first_users_record do
    dbc = databases.export
    reader = dbc.create_command(%{SELECT * FROM "user"}).execute_reader
    result = reader.each { |x| break x }
    reader.close
    result
  end

  let :first_activity_record do
    dbc = databases.export
    reader = dbc.create_command(%{SELECT * FROM "activity"}).execute_reader
    result = reader.each { |x| break x }
    reader.close
    result
  end

  context "a new record" do
    it "saves the data correctly" do
      squeal_basic_users_document
      result = first_users_record

      result['name'].should == 'Test User'

      result['dob'].mday.should == 4
      result['dob'].mon.should == 7
      result['dob'].year.should == 1776

      result['gender'].should == 'M'

      result['foreign'].should be_true
      result['dull'].should be_false

      result['symbolic'].should == :of_course.to_s

      result['interests'].should == 'health,education'
    end

    it "saves embedded documents correctly" do
      squeal_users_document_with_activities
      result = first_activity_record

      result['name'].should == 'Be independent'
      result['due_date'].mday.should == (today + 1).mday
      result['due_date'].mon.should == (today + 1).mon
      result['due_date'].year.should == (today + 1).year
    end
  end

  context "an existing record" do
    it "updates the data correctly" do
      squeal_basic_users_document
      squeal_basic_users_document(users_document.merge('foreign' => false, 'gender' => 'F'))

      result = first_users_record

      result['name'].should == 'Test User'

      result['dob'].mday.should == 4
      result['dob'].mon.should == 7
      result['dob'].year.should == 1776

      result['gender'].should == 'F'

      result['foreign'].should be_false
      result['dull'].should be_false

      result['symbolic'].should == :of_course.to_s

      result['interests'].should == 'health,education'
    end

    it "updates the child record correctly" do
      squeal_users_document_with_activities(users_document.merge('activities' => [{ :_id => 'a1', 'name' => 'Be expansionist', 'due_date' => as_time(today + 1) }]))
      result = first_activity_record

      result['name'].should == 'Be expansionist'
      result['due_date'].mday.should == (today + 1).mday
      result['due_date'].mon.should == (today + 1).mon
      result['due_date'].year.should == (today + 1).year
    end
  end
end
