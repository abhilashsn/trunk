class AbaDdaLookup < ActiveRecord::Base
  belongs_to :facility
  has_many  :cr_transactions
end
