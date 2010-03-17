require 'squealer'

import_db('pharmmd_production')
export_db('pharmmd_reporting_export')

Squealer.import("patients").find({}).each do |patient|
  target(:patient, patient.id) do |_target|  # insert or update on patient where id is primary key column name
      _target.assign(:name) { patient[first_name] + " " + patient[last_name].upcase }
      _target.assign(:dob) { patient[date_of_birth] }
      _target.assign(:latest_drug) { patient.medications.last.name } # dubious

      patient.medications.each do |med|
        target(:medication, med.id) do |_target|
          _target.assign(:patient_id) { patient.id }
          _target.assign(:name) { med.name }
        end

        med.prescriptions.each do |rx|
          target(:prescription, rx.id) do |_target|
            _target.assign(:patient_id) { patient.id }
            _target.assign(:medication_id) { med.id }
            _target.assign(:dispense_date) { rx.dispense_date }
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

    target :organization do
    end

  else
    # something else
  end
end
