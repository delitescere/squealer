require 'squealer'

# connect to the source mongodb database
import 'localhost', 27017, 'development'

# connect to the target mysql database
export 'mysql', 'localhost', 'root', '', 'reporting_export'

import.source('users').each do |user|
  target(:user) do
    assign(:name) { "#{user.last_name.upcase}, #{user.first_name}" }
    assign(:dob) { user.date_of_birth }
    assign(:gender) #or# assign(:gender) { user.gender }

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

    # You can denormalize the export...
    # user.home_address = { street: '661 W Lake St', city: 'Chicago', state: 'IL' }
    assign(:home_address) { flatten_address(user.home_address) } # flatten_address is some custom method of yours
    assign(:work_address) { flatten_address(user.work_address) }

    user.activities.each do |activity|
      target(:activity) do
        assign(:user_id) #or# assign(:user_id) { user._id }
        assign(:name)
        assign(:due_date)
      end

      activity.tasks.each do |task|
        target(:task) do
          assign(:user_id)
          assign(:activity_id)
          assign(:due_date)
        end
      end #activity.tasks
    end #user.activities
  end
end #collection("users")

# Here we use a procedural "join" on related collections to update a target...
import.source('organizations', {'disabled_date' => {'exists' => true}}).each do |organization|
  import.source('users', {'organization_id' => organization.id}) do |user|
    target(:user) do
      assign(:disabled) { true }
    end
  end
end
