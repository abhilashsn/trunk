namespace :rails do
  desc "Warn deprecated code" 
  task :deprecated => :environment do
    deprecated = {
      '@params'    => 'Use params[] instead',
      '@session'   => 'Use session[] instead',
      '@flash'     => 'Use flash[] instead',
      '@request'   => 'Use request[] instead',
      '@env' => 'Use env[] instead',
      'find_all'   => 'Use find(:all) instead',
      'find_first' => 'Use find(:first) instead',
      'render_partial' => 'Use render :partial instead',
      'component'  => 'Avoid use it',
      'paginate'   => 'Moved to plugin',
      'start_form_tag'   => 'Use form_for instead',
      'end_form_tag'   => 'Use form_for instead',
      ':post => true'   => 'Use :method => :post instead',
      'auto_complete' => 'Moved to plugin',
      'breakpoint_server' => 'Has no effect',
      'acts_as_tree' => 'Moved to plugin'
    }

    deprecated.each do |key, warning|
      puts '--> ' + key
      output = `cd '#{File.expand_path('app', Rails.root)}' && grep -n --exclude=*.svn* -r '#{key}' *`
      unless output =~ /^$/
        puts "  !! " + warning + " !!" 
        puts '  ' + '.' * (warning.length + 6)
        puts output
      else
        puts "Clean" 
      end
      puts
    end
  end

  desc "Rename all views to Rails 2.x convention"
  task "rename_views" do
    Dir.glob('app/views/**/[^_]*.rhtml').each do |file|
      `svn mv #{file} #{file.gsub(/\.rhtml$/, '.html.erb')}`
    end

    Dir.glob('app/views/**/[^_]*.rxml').each do |file|
      `svn mv #{file} #{file.gsub(/\.rxml$/, '.xml.builder')}`
    end

    Dir.glob('app/views/**/[^_]*.rjs').each do |file|
      `svn mv #{file} #{file.gsub(/\.rjs$/, '.js.rjs')}`
    end
    Dir.glob('app/views/**/[^_]*.haml').each do |file|
      `svn mv #{file} #{file.gsub(/\.haml$/, '.html.haml')}`
    end
  end
  
  desc "Rename migration to Rails 2.x convention"
  task "rename_migrations" => :environment do
    migration_time_stamp = Time.now - 1.year
    Dir.glob("db/migrate/**").each do |file|
      migration_time_stamp += 1.hour
      timestamp = migration_time_stamp.utc.strftime("%Y%m%d%H%M%S")
      old_version = file[/\/[0-9]*_/].delete("_\/")
      # TODO: Create a separate task to modify the info in production database
      # ActiveRecord::Base.connection.execute("update schema_migrations set version=#{timestamp} where version=#{old_version}")
        `svn mv #{file} #{file.gsub(old_version, "#{timestamp}")}`
    end
  end

  desc "Update version info in the database"
  task "update_versions" => :environment do
    ActiveRecord::Base.connection.execute("delete from schema_migrations")
    Dir.glob("db/migrate/**").each do |file|
      version = file[/\/[0-9]*_/].delete("_\/")
      ActiveRecord::Base.connection.execute("insert into schema_migrations(version) values(#{version})")
    end
  end
end
