module AdjustmentReason

  def adjustment_reason_elements
    ['noncovered', 'denied', 'discount', 'coinsurance', 'deductible', 'copay',
      'primary_payment', 'contractual', 'miscellaneous_one', 'miscellaneous_two']
  end

  def pr_adjustment_reason_elements
    ['coinsurance', 'deductible', 'copay']
  end

  def self.included(other)
    other.extend(self)
  end
   
end
