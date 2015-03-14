desc "Import ACH"
task :import_ach, [:filename] => [:environment] do |t, args|

  file_name = args[:filename]
  file_location = "#{Rails.root}/private/unzipped_files/" + file_name

  AchFile.parse_file_info(file_name, file_location)
  
end
