require 'squealer'

import('pharmmd_production')
export('pharmmd_reporting_export')

Squealer.import("patients").find({}).each do |patient|
  target(:patient, patient.id) do |target|  # insert or update on patient where id is primary key column name
      target.assign(:name) { patient[first_name] + " " + patient[last_name].upcase }
      target.assign(:dob) { patient[date_of_birth] }
      target.assign(:latest_drug) { patient.medications.last.name } # dubious

      patient.medications.each do |med|




        target(:medication, med.id) do
          assign(:patient_id) { patient.id }
          assign(:name) { med.name }
        end






        med.prescriptions.each do |rx|
          target(:prescription, rx.id) do |target|
            target.assign(:patient_id) { patient.id }
            target.assign(:medication_id) { med.id }
            target.assign(:dispense_date) { rx.dispense_date }
          end
        end
      end

    end
  end
end

Organization.collection.find({}).each do |organization|
  if organization.disabled
    Patient.collection.find({ :organization_id => organization.id }) do |patient|
      target(:patient, patient.id) do |target|
        target.assign(:disabled) { true }
      end
    end

    target(:organization, organization.id) do |target|
    end

  else
    # something else
  end
end
