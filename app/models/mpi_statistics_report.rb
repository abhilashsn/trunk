class MpiStatisticsReport < ActiveRecord::Base
  belongs_to :user
  belongs_to :eob, :polymorphic => true
  belongs_to :batch

  def self.create_mpi_stat_report(parameters = {}, to_save = true)
    activity = self.new({
        :batch_id => parameters[:batch_id],
        :user_id => parameters[:user_id],
        :mpi_status => parameters[:mpi_status],
        :search_criteria => parameters[:search_criteria],
        :start_time => parameters[:start_time],
        :eob_id => parameters[:eob_id]
      })
    if to_save
      activity.save
    else
      activity
    end
  end

  def insurance_payment_eob
    eob if eob_type == 'InsurancePaymentEob'
  end

  def patient_pay_eob
    eob if eob_type == 'PatientPayEob'
  end
  
end
