module OperationLog
  module BarnabaCheck    
    def eval_correspondence
      "YES"
    end

    def eval_image_id
      get_multipage_image_name(batch, check, eob)
    end
  end
end
