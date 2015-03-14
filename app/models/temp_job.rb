class TempJob < ActiveRecord::Base
  belongs_to :job
  validate :validate_images
  validates :check_number, :check_amount, :image_from, presence: true
  validates :check_number, numericality: { only_integer: true }
  validates :check_amount, numericality: true
  validates :image_to, presence: true if :image_count.blank?
  validates :image_count, presence: true if :image_to.blank?

  with_options unless: (:correspondence? || :upmc_job?) do |temp_job|
    temp_job.validates :aba_number, presence: true, numericality:
      { only_integer: true }, length: { is: 9 }, allow_blank: false, format: /[^0*]/
    temp_job.validates :account_number, presence: true, numericality:
      { only_integer: true }, length: { in: 3..14 }, allow_blank: false, format: /[^0*]/
  end

  with_options if: (:correspondence? || :upmc_job?) do |temp_job|
    temp_job.validates :aba_number, numericality: { only_integer: true },
      length: { is: 9 }, allow_blank: true, format: /[^0*]/
    temp_job.validates :account_number, numericality: { only_integer: true },
      length: { in: 3..14 }, allow_blank: true, format: /[^0*]/
  end
  before_save :process_images
  after_destroy :reset_images
  attr_accessor :parent_job_remaining_images
  attr_accessor :parent_job_all_images

  UPMC = 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER'

  def validate_images
    from_index, to_index = nil, nil
    compute_image_related_entities
    
    if image_count_valid?
      parent_job_remaining_images.each_with_index do |img, i|
        from_index = i if img.image_file_name == image_from
        to_index = i if img.image_file_name == image_to
      end
      if image_from.present? && image_to.present?
        errors.add(:image_from, "should be <= Image to") unless from_index <= to_index
        else
        errors.add(:image_from, "is mandatory") if image_from.nil?
        errors.add(:image_to, "is mandatory") if image_to.nil?
      end
    end
  end

  def self.get_image_ids(parent_job_id)
    image_ids = []
    temp_jobs = TempJob.where(:job_id => parent_job_id)
    parent_job_images = temp_jobs[0].parent_job_all_images if temp_jobs.present?
    temp_jobs.each do |temp_job|
      from_index = temp_job.image_from_index
      to_index = temp_job.image_to_index
      images = parent_job_images.values_at(from_index..to_index) if from_index.present? && to_index.present?
      image_ids << images.map(&:id) if images.present?
    end
    image_ids.flatten
  end

  def image_from_index
    from_index = nil
    parent_job_all_images.each_with_index do |img, i|
      from_index = i if img.image_file_name == image_from
    end
    from_index
  end

  def image_to_index
    to_index = nil
    parent_job_all_images.each_with_index do |img, i|
      to_index = i if img.image_file_name == image_to
    end
    to_index
  end

  def process_images
    temp_job_images = parent_job_remaining_images[image_from_index..image_to_index]
    temp_job_image_ids = temp_job_images.map(&:id)
    remaining_images = parent_job_remaining_images.reject{|img| temp_job_image_ids.include?img.id}
    ImagesForJob.reset_page_numbers_of_images(remaining_images)
    last_index = remaining_images.length
    temp_job_images.each_with_index do |img, i|
      img.image_number = last_index + i + 1
      img.save
    end
  end

  def reset_images
    ImagesForJob.reset_page_numbers_of_images(parent_job_remaining_images)
  end

  def parent_job_remaining_images
    @parent_job_remaining_images = []
    all_images = job.images_for_jobs.sort{|a,b| a.image_number <=> b.image_number}
    temp_job_image_ids = TempJob.get_image_ids(job.id)
    #remove the job currently being deleted
    temp_job_image_ids = temp_job_image_ids.delete_if { |id| id = self.id  }
    if temp_job_image_ids.present?
      @parent_job_remaining_images = all_images.reject{|img| temp_job_image_ids.include?img.id}
    else
      @parent_job_remaining_images = all_images
    end
  end

  def parent_job_all_images
    @parent_job_all_images = job.images_for_jobs.sort{|a,b| a.image_number <=> b.image_number}
  end

  private
  def image_count_valid?
    if image_count == @parent_job_image_count
      errors[:base] << "Child job cannot have all the images of parent"
      false
    elsif (!(image_count < @parent_job_image_count) || !(image_count >= 1))
      errors.add(:image_count, "should be between 1 to #{@parent_job_image_count - 1}")
      false
    else
      true
    end
  end

  def compute_image_related_entities    
    @parent_job_image_count = parent_job_remaining_images.count
    if image_from.present? && image_to.present?
      self.image_count = compute_image_count
    elsif image_count.present? && image_from.present?
      self.image_to = compute_image_to
    else
      errors[:base] << "Image From and either of Image To or Page Count is mandatory"
    end
  end

  def correspondence?
    check_number.to_s.strip.to_i.zero? unless check_number.blank?
  end

  def upmc_job?
    client_name = job.batch.facility.client.name
    client_name == UPMC
  end
  
  def compute_image_to
    image_to = nil
    from_index = image_from_index
    if from_index.present?
      to_index = from_index + image_count - 1
      image_to = parent_job_remaining_images.values_at(to_index)
      image_to = image_to[0].image_file_name if image_to.present?
    end
    image_to
  end

  def compute_image_count
    image_count = nil
    if image_from_index.present? && image_to_index.present?
      image_count = image_to_index - image_from_index + 1
    end
    image_count
  end
  
end
