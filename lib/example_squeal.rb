require 'squealer'

import('localhost', 27017, 'development')
export('localhost', 'root', '', 'reporting_export')

import.collection("users").find({}).each do |user|
  target(:user, user._id) do  # insert or update on user where id is primary key column name
    assign(:name) { user.first_name + " " + user.last_name.upcase }
    assign(:dob) { user.dob }

    user.activities.each do |activity|
      target(:activity, activity._id) do
        assign(:user_id) { user._id }
        assign(:name) { activity.name }
      end

      activity.tasks.each do |task|
        target(:task, task._id) do
          assign(:user_id) { user._id }
          assign(:activity_id) { activity._id }
          assign(:date) { task.date }
        end
      end #activity.tasks
    end #user.activities
  end
end #collection("users")

import.collection("organization").find({}).each do |organization|
  if organization.disabled
    import.collection("users").find({ :organization_id => organization.id }) do |user|
      target(:user, user.id) do
        assign(:disabled) { true }
      end
    end
  else
    # something else
  end
end
