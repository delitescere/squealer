require 'squealer'

import('pharmmd_development')
export('pharmmd_reporting_export')

Database.instance.import.collection("patients").find({}).each do |patient|
  target(:patient, patient._id) do  # insert or update on patient where id is primary key column name
    assign(:name) { patient.first_name + " " + patient.last_name.upcase }
    assign(:dob) { patient.dob }

    patient.medications.each do |med|
      target(:medication, med._id) do
        assign(:patient_id) { patient._id }
        assign(:name) { med.name }
      end

      med.prescriptions.each do |rx|
        target(:prescription, rx._id) do
          assign(:patient_id) { patient._id }
          assign(:medication_id) { med._id }
          assign(:dispense_date) { rx.dispense_date }
        end
      end #med.prescriptions
    end #patient.medications
  end
end #collection("patients")





Organization.collection.find({}).each do |organization|
  if organization.disabled
    Patient.collection.find({ :organization_id => organization.id }) do |patient|
      target(:patient, patient.id) do
        assign(:disabled) { true }
      end
    end

    target(:organization, organization.id) do
    end

  else
    # something else
  end
end
