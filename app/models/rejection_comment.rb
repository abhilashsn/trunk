class RejectionComment < ActiveRecord::Base
  belongs_to :facility
  validates_presence_of :name

  def self.find_complete_and_incomplete_rejection_comments(facility_id)
    complete_rejection_comments, incomplete_rejection_comments, orbo_rejection_comments = nil, nil, nil
    rejection_comments = RejectionComment.where("facility_id = #{facility_id} AND (job_status = 'incomplete' OR job_status = 'complete' OR job_status = 'orbo_rejection')")
    rejection_comments.each do |comment|
      if incomplete_rejection_comments.blank? && comment.job_status.to_s.downcase == 'incomplete'
        incomplete_rejection_comments = comment
      end
      if complete_rejection_comments.blank? && comment.job_status.to_s.downcase == 'complete'
        complete_rejection_comments = comment
      end
      if orbo_rejection_comments.blank? && comment.job_status.to_s.downcase == 'orbo_rejection'
        orbo_rejection_comments = comment
      end
      if incomplete_rejection_comments.present? && complete_rejection_comments.present? && orbo_rejection_comments.present?
        break
      end
    end
    return complete_rejection_comments, incomplete_rejection_comments, orbo_rejection_comments
  end

end
