require 'squealer'

import('pharmmd_production')
export('pharmmd_reporting_export')

Squealer.import("patients").find({}).each do |patient|
  target(:patient, patient.id) do  # insert or update on patient where id is primary key column name
      assign(:name) { patient[first_name] + " " + patient[last_name].upcase }
      assign(:dob) { patient[date_of_birth] }
      assign(:latest_drug) { patient.medications.last.name } # dubious

      patient.medications.each do |med|
        target(:medication, med.id) do
          assign(:patient_id) { patient.id }
          assign(:name) { med.name }
        end

        med.prescriptions.each do |rx|
          target(:prescription, rx.id) do
            assign(:patient_id) { patient.id }
            assign(:medication_id) { med.id }
            assign(:dispense_date) { rx.dispense_date }
          end
        end
      end
    end
  end
end

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
