class ChangeColumnDefaultOfClientTable < ActiveRecord::Migration
  def change
    change_column_default :clients, :internal_tat,nil
    change_column_default :clients, :tat,nil
    change_column_default :clients, :max_eobs_per_job,nil
    change_column_default :clients, :max_jobs_per_user_client_wise,nil
    change_column_default :clients, :max_jobs_per_user_payer_wise,nil
    change_column_default :clients, :contracted_tat,nil

  end

end
