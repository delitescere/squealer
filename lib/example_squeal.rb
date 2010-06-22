require 'squealer'

# connect to the source mongodb database
import('localhost', 27017, 'development')

# connect to the target mysql database
export('mysql', 'localhost', 'root', '', 'reporting_export')

# Here we extract, transform and load all documents in a collection...

#
# You don't want to use a find() on the MongoDB collection...
#   import.source("users") { |users| users.find_one() }.each do |user|
#
# Also accepts optional conditions...
#   import.source("users", "{disabled: 'false'}").each do |user|
#
# Defaults to find all...
import.source('users').each do |user|
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
    assign(:gender) #or# assign(:gender) { user.gender }

    #
    # You can normalize the export...
    # home_address and work_address are a formatted string like: "661 W Lake St, Suite 3NE, Chicago IL, 60611, USA"
    addresses = []
    addresses << atomize_address(user.home_address) # atomize_address is some custom method of yours
    addresses << atomize_address(user.work_address)
    addresses.each do |address|
      target(:address) do
        assign(:street)
        assign(:city)
        assign(:state)
        assign(:zip)
      end
    end

    #
    # You can denormalize the export...
    # user.home_address = { street: '661 W Lake St', city: 'Chicago', state: 'IL' }
    assign(:home_address) { flatten_address(user.home_address) } # flatten_address is some custom method of yours
    assign(:work_address) { flatten_address(user.work_address) }

    user.activities.each do |activity|
      target(:activity) do
        #
        # You can use an empty block to infer the value from the '_id' field
        # of a parent document where the name of the parent collection matches
        # a variable that is in scope...
        assign(:user_id) #or# assign(:user_id) { user._id }
        assign(:name) #or# assign(:name) { activity.name }
        assign(:due_date) #or# assign(:due_date) { activity.due_date }
      end

      activity.tasks.each do |task|
        target(:task) do
          assign(:user_id) #or# assign(:user_id) { user._id }
          assign(:activity_id) #or# assign(:activity_id) { activity._id }
          assign(:due_date) #or# assign(:due_date) { task.due_date }
        end
      end #activity.tasks
    end #user.activities
  end
end #collection("users")

# Here we use a procedural "join" on related collections to update a target...
import.source('organizations', {'disabled_date' => {'exists' => true}}).each do |organization|
  import.source('users', {'organization_id' => organization.id}) do |user|
    target(:user) do
      #
      # Source boolean values are converted to integer (0 or 1)...
      assign(:disabled) { true }
    end
  end
end
