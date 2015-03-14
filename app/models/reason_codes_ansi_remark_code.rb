class ReasonCodesAnsiRemarkCode < ActiveRecord::Base
   belongs_to :reason_code
   belongs_to :ansi_remark_code
end
