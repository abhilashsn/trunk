module OperationLog
  module GoodmanCampbellBrainAndSpineCheck    
    def eval_image_id
      job = check.job
      job.initial_image_name unless job.initial_image_name.blank?
    end    
  end
end
