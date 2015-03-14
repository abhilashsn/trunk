class RenamePayerOnbaseRelationsTableAndAddNewColumns < ActiveRecord::Migration
  def change
    if ActiveRecord::Base.connection.table_exists?(:payer_onbase_relations)
      rename_table :payer_onbase_relations, :facilities_payers_informations
    end
    
    if ActiveRecord::Base.connection.table_exists?(:facilities_payers_informations)    
      unless ActiveRecord::Base.connection.column_exists?(:facilities_payers_informations, :in_patient_payment_code)
        add_column :facilities_payers_informations, :in_patient_payment_code, :string, :limit => 25
      end
      unless ActiveRecord::Base.connection.column_exists?(:facilities_payers_informations, :out_patient_payment_code)
        add_column :facilities_payers_informations, :out_patient_payment_code, :string, :limit => 25
      end
      unless ActiveRecord::Base.connection.column_exists?(:facilities_payers_informations, :in_patient_allowance_code)
        add_column :facilities_payers_informations, :in_patient_allowance_code, :string, :limit => 25
      end
      unless ActiveRecord::Base.connection.column_exists?(:facilities_payers_informations, :out_patient_allowance_code)
        add_column :facilities_payers_informations, :out_patient_allowance_code, :string, :limit => 25
      end
      unless ActiveRecord::Base.connection.column_exists?(:facilities_payers_informations, :capitation_code)
        add_column :facilities_payers_informations, :capitation_code, :string, :limit => 25
      end
    end
  end
end

