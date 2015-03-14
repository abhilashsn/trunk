namespace :output do

  desc "Task for converting 4010 835 files to 5010 "
  task :generate_5010, [:file_path]  => [:environment] do |t, args|
    mapping_hash = {0 => {:segment => 12, :value => "00501"}, 1 => {:segment => 8, :value =>  "005010X221~\n"}}
    folder_5010 = FileUtils.mkdir_p("#{args.file_path}/5010")
    Dir.glob("#{args.file_path}/*").each do |file|
      if File.file? file
        array_of_lines = File.readlines(file)
        array_of_lines[0..1].each_with_index do |line, i|
          row = line.split('*')
          row[mapping_hash[i][:segment]] = mapping_hash[i][:value]
          array_of_lines[i] = row.join('*')
          File.open("#{folder_5010}/#{File.basename(file)}", 'w') do |f|
            f.write array_of_lines
          end
        end
      end
    end
  end

end


