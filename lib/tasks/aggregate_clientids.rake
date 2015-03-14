namespace :aggregate do
  desc 'Aggregating Non Contracted Client Ids'

  task :clientid => :environment do
      # This task aggregates non contracted client ids from 837 file..
      FileUtils.mkdir_p("#{Rails.root}/837/NewClients/Navicure/Archive") unless File.exists? "#{Rails.root}/837/NewClients/Navicure/Archive"
      FileUtils.mkdir_p("#{Rails.root}/837/NewClients/Navicure/consolidated_client_ids/#{Time.now.strftime('%m%d%Y')}") unless File.exists? "#{Rails.root}/837/NewClients/Navicure/consolidated_client_ids/#{Time.now.strftime('%m%d%Y')}"
      begin
        arr = ""
        Dir.glob("#{Rails.root}/837/NewClients/Navicure/*.txt").each do |txt|
          if arr.blank?
            arr = arr + File.open(txt).readlines.join.split("\n").uniq.join(',')
          else
            arr = arr + "," + File.open(txt).readlines.join.split("\n").uniq.join(',')
          end
          system "mv #{txt} #{Rails.root}/837/NewClients/Navicure/Archive/" # Archieving the already processed TXT files.
        end
        new_uniqe_client_ids = arr.split(',').uniq
        unique_client_id_file = File.open("#{Rails.root}/837/NewClients/Navicure/consolidated_client_ids/#{Time.now.strftime('%m%d%Y')}" + "/#{Time.now.strftime('%m%d%Y%H%M%S')}_clientids.txt",'w') do |f|
          new_uniqe_client_ids.each do |client_id|
            f.puts client_id
          end
        end
        if new_uniqe_client_ids.length > 0
          p "#{new_uniqe_client_ids.length} new client ids are logged"
          p "The files are archived into '/837/NewClients/Navicure/Archive' directory"
        else
          p "No New client ids"
        end
      rescue Exception => e
        p "An Exception has occured.The error is.................."
        p e.message
      end
  end # Rake task block ends here.

end # NameSpace block ends here.