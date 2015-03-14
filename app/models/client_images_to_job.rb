class ClientImagesToJob < ActiveRecord::Base
  belongs_to :job
  belongs_to :images_for_job
end
