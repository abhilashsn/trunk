require 'OCR_Data'
include OCR_Data
class ImagesForJob < ActiveRecord::Base
  
  #   RAILS3.1 TODO
  #   has_attachment :content_type => :image,
  #    :storage => :file_system ,
  #        :resize_to=>'930X1196',
  #  :max_size=>195.megabytes,
  #    :path_prefix => 'private/unzipped_files',
  #    :processor=>'Rmagick'

  has_attached_file :image, :styles => { :medium => "300x300>" },
    :url => "/unzipped_files/:id_partition/:basename:style.:extension",
    :path => ":rails_root/private/unzipped_files/:id_partition/:basename:style.:extension"
                            
  
  has_many :client_images_to_jobs,:dependent=>:destroy
  has_many :jobs,:through=>:client_images_to_jobs
  has_many :image_types
  belongs_to :batch
  # to associate columns that are read by the OCR with their metadata column "details"
  #Fields listed below will have their meta data stored in "details"
  has_details :filename

  #creating alias for the old columns of attachment_fu which are renamed for paperclip....
  alias_attribute :filename, :image_file_name
  alias_attribute :content_type, :image_content_type
  alias_attribute :size, :image_file_size

  after_update :create_qa_edit
  def create_qa_edit
    QaEdit.create_records(self)
  end
  
  def base_path
    return File.join(Rails.root, 'private')
  end

  # The method returns the original image file name.
  # The image files are passed through a 'Splitter' script which changes the file name.
  # It duplicates the name.
  # The method removes the duplicates in the image file name if any.
  def original_file_name
    file_name_parts = filename.split('_')   
    if file_name_parts.length > 0
      last_occurrence = nil
      first_element = file_name_parts[0]
      if Output835.element_duplicates?(first_element, file_name_parts)
        last_occurrence = file_name_parts.rindex(first_element)
      end
      last_occurrence ||= file_name_parts.length
      # Fetch the first n ( where n = last_occurrence ) elements of the array, until the first element duplicates.
      normalized_file_name_parts = file_name_parts.first(last_occurrence)
      normalized_file_name = normalized_file_name_parts.join('_')
      if Output835.element_duplicates?(first_element, file_name_parts)
        # Only for the duplicating file names, the extension of the file is appended to the normalized_file_name.
        # For others, the normalized_file_name itself has the extension.
        image_format_extension = batch.facility.image_file_format
        normalized_file_name << '.' << image_format_extension.downcase
      end
      normalized_file_name
    else
      filename
    end
  end

  #Rails3 this is a wrapper to avatar
  def public_filename (type=nil)
    self.image.url(type)
  end

  def public_filename_url (type=nil)
    self.image.path(type)
  end

  # This method returns the image type for the current image (self object) based on business rules:
  # The doc set in the Transaction XML should contain each image once and only once, regardless of how many imge types it has.
  # Image with CHK and EOB image types - This happens when a balancing record is created from a Check image.
  # In this case the image should be referenced as a CHK in the Transaction XML
  # Image with CHK and EOB image types - This happens due to scanning errors, where the lockbox scans both the check and and EOB in the same page.
  # In this case the image will be referenced as a CHK in the Transaction XML
  # Image with ENV and EOB image types - This happens when a balancing record is created from an ENV image.
  # In this case the image will be referenced as an EOB in the Transaction XML
  def image_type_for_transaction
    if image_types.length > 0
      all_image_types = image_types.map(&:image_type).uniq
      if all_image_types.length == 1
        image_type = all_image_types.first
      elsif all_image_types.include?('CHK') && all_image_types.include?('EOB')
        image_type = 'CHK'
      elsif all_image_types.include?('ENV') && all_image_types.include?('EOB')
        image_type = 'EOB'       
      end
    end
    image_type
  end

  def is_check_image_type?
    unless image_types.blank?
      image_type = image_types.any?{|image_type| image_type.image_type == 'CHK' }
    end
  end

  def exact_file_name
    extension = File.extname(filename)
    splitted_file_name = filename.split('_')
    if splitted_file_name.length > 1
      last_index_number = splitted_file_name.last.split(".").first
      if last_index_number.match(/^[0-9]*$/) == nil
        exact_file_name = filename
      else
        splitted_file_name.pop(1)
        if splitted_file_name.length > 1
          exact_file_name = splitted_file_name.join('_') + extension
        else
          exact_file_name = splitted_file_name.join('') + extension
        end
      end
    else
      filename
    end
  end

  def self.reset_page_numbers_of_images(images)
    images = images.sort{|a,b| a.image_number <=> b.image_number}
    images.each_with_index do |img, i|
      img.image_number = i + 1
      img.save
    end
  end

  def self.get_image_records_in_order(images_for_job_ids)
    image_array_hash = {}
    images = []
    if images_for_job_ids.length > 0
      image_array = self.where(:id => images_for_job_ids)
      if image_array.length > 0
        image_array.each do |record|
          image_array_hash[record.id] = record
        end
        images_for_job_ids.each do |images_for_job_id|
          images << image_array_hash[images_for_job_id]
        end
      end
    end
    images
  end

end
