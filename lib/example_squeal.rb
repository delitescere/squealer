require 'squealer'

# connect to the source mongodb database
import('localhost', 27017, 'development')

# connect to the target mysql database
export('localhost', 'root', '', 'reporting_export')

# Here we extract, transform and load all documents in a collection...
import.collection("users").find({}).each do |user|
  # Insert or Update on table 'user' where 'id' is the column name of the primary key.
  #
  # The primary key value is taken from the '_id' field of the source document,
  # referenced using a variable with the same name as the table name passed to target().
  #
  # The block parameter |user| above, matches the target() parameter :user below...
  target(:user) do
    #
    # assign() takes a column name and a block to set the value.
    #
    # You can use an valid arbitrary expression...
    assign(:name) { "#{user.last_name.upcase}, #{user.first_name}" }
    #
    # You can use a simple access on the source document...
    assign(:dob) { user.date_of_birth }
    #
    # You can use an empty block to infer the value from a field of the same
    # name on the source document...
    assign(:gender) {} #or# assign(:gender) { user.gender }

    user.activities.each do |activity|
      target(:activity) do
        #
        # You can use an empty block to infer the value from the '_id' field
        # of a parent document where the name of the parent collection matches
        # a variable that is in scope.
        #
        assign(:user_id) {} #or# assign(:user_id) { user._id }
        assign(:name) {} #or# assign(:name) { activity.name }
        assign(:due_date) {} #or# assign(:due_date) { activity.due_date }
      end

      activity.tasks.each do |task|
        target(:task) do
          assign(:user_id) {} #or# assign(:user_id) { user._id }
          assign(:activity_id) {} #or# assign(:activity_id) { activity._id }
          assign(:due_date) {} #or# assign(:due_date) { task.due_date }
        end
      end #activity.tasks
    end #user.activities
  end
end #collection("users")

# Here we use a procedural "join" on related collections to update a target...
import.collection("organization").find({'disabled_date' : { 'exists' : 'true' }}).each do |organization|
  import.collection("users").find({ :organization_id => organization.id }) do |user|
    target(:user) do
      #
      # Source boolean values are converted to integer (0 or 1)...
      assign(:disabled) { true }
    end
  end
end
