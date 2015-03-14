namespace :ocr do
  desc 'Folder structure generation for MedAssets OCR'

  task :medassets_folderstructure => :environment do


    # This script is used for unzipping the image folder and generating the required folder structure for OCR.
    # to-ocr-server is the folder to place the image zip folder.
    # ocr_folder_structure is the intermediate folder for generating folder structure on the unzipped images.
    # Folder structure for medassets means one folder for one check image and its corresponding eobs with the folder containing a okb file 'ocr.txt' which is a signal file for the hotspot to recognize the end of documents in that folder.
    # ocr_input is hot spot source folder for OCR.
    # XMLs_New is the hot spot outlet into which the xmls are generated.

    require 'rubygems'
    require 'ftools'
    require 'zip/zipfilesystem'
    path = "/home/medassets/ocr_input/*.tif"
    source_zip="/home/medassets/to-ocr-server/*.zip"
    output = "#{Rails.root}/XMLs_New/*"
    
    def ocr_folder_structure
      target_dat_location = "/home/medassets/ocr_folder_structure/*.dat"
      target_tif_location = "/home/medassets/ocr_folder_structure/*"
      Dir.glob(target_dat_location).each do |doc|
        file=File.open("#{doc}","r")
    
        while file_content = file.gets
          unless file_content.strip == ""
            file_line_array  = file_content.split(" ")
            if file_line_array[5] == "1CK"

              check_name = file_line_array[6].split(".")
              check_name_new = check_name[1][2,check_name[1].size-1]

              Dir.mkdir("/home/medassets/ocr_folder_structure/#{check_name_new}")

              data_file = Dir.glob("#{target_tif_location}")

              image_file_index=data_file.index("/home/medassets/ocr_folder_structure/#{ file_line_array[9]}")
  
              FileUtils.mv("#{data_file[image_file_index]}","/home/medassets/ocr_folder_structure/#{check_name_new}")
              new_file=File.new("/home/medassets/ocr_folder_structure/#{check_name_new}/ocr.txt",'w')
              new_file.close
        
            else
              data_file = Dir.glob("#{target_tif_location}")

              image_file_index=data_file.index("/home/medassets/ocr_folder_structure/#{ file_line_array[5]}")
              FileUtils.mv("#{data_file[image_file_index]}","/home/medassets/ocr_folder_structure/#{check_name_new}")
            end
          end
        end
        file.close

  
        File.delete('/home/medassets/ocr_folder_structure/images.dat')
      end
    end
    
   
    path1 = "/home/medassets/ocr_folder_structure"

    # Unzipping the zip folder in to-ocr-server and moving images into ocr_folder_structure.
    sleep 5
    Dir.glob(source_zip).each do |doc|
      p "Unzipping the folder"
      sleep 5
      Zip::ZipFile.open(doc) do |zipfile|
        zip_dir = zipfile.dir
        zip_dir.entries('.').each do |entry|
          zipfile.extract(entry , "#{path1}/#{entry}")
        end
      end
      
      # Deleting the documents in the zip folder after extraction.

      File.delete(doc)
    end
    sleep 5
    
    # Generating folder structure.

    ocr_folder_structure
    sleep 5
    output1 = "/home/medassets/ocr_input"
    path = "/home/medassets/ocr_folder_structure/*"
    
    # Moving the folders to ocr_input which is the hotspot inlet.
    folder_count = 0
    Dir.glob(path).each do |doc|
      folder_count += 1
      FileUtils.mv("#{doc}","#{output1}")
    end    
    file=File.new("#{Rails.root}/XMLs_New/xmlcount.txt",'w')
    file.puts(folder_count)
    file.close
  end
end

