require 'rubygems'
require 'zip/zip'
require 'find'
require 'fileutils'
gem 'rubyzip'
require 'zip/zip'
require 'zip/zipfilesystem'
class Zipper

  #Zipping directory with subfolders
  def self.compress_folder(path)
    path.sub!(%r[/$],'')
    archive = File.join(path,File.basename(path))+'.zip'
    FileUtils.rm archive, :force=>true

    Zip::ZipFile.open(archive, 'w') do |zipfile|
      Dir["#{path}/**/**"].reject{|f|f==archive}.each do |file|
        zipfile.add(file.sub(path+'/',''),file)
      end
    end
  end

 #Zipping directory
 def self.zip(dir, zip_dir, remove_after = false)
    Zip::ZipFile.open(zip_dir, Zip::ZipFile::CREATE)do |zipfile|
      Find.find(dir) do |path|
        Find.prune if File.basename(path)[0] == ?.
        dest = /#{dir}\/(\w.*)/.match(path)
        # Skip files if they exists
        begin
          zipfile.add(dest[1],path) if dest
        rescue Zip::ZipEntryExistsError
        end
      end
    end
    FileUtils.rm_rf(dir) if remove_after
  end


  #Unzipping directory
  def self.unzip(zip, unzip_dir, remove_after = false)
    Zip::ZipFile.open(zip) do |zip_file|
      zip_file.each do |f|
        f_path=File.join(unzip_dir, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      end
    end
    FileUtils.rm(zip) if remove_after
  end

  #Retrieving single file content
  def self.open_one(zip_source, file_name)
    Zip::ZipFile.open(zip_source) do |zip_file|
      zip_file.each do |f|
        next unless "#{f}" == file_name
        return f.get_input_stream.read
      end
    end
    nil
  end

  private
  #Encoding conversion not in use
  def fix_cp1252_utf8(text)
    text.force_encoding('windows-1252').encode('cp1252',
                :fallback => {
                  "\u0081" => "\x81".force_encoding("cp1252"),
                  "\u008D" => "\x8D".force_encoding("cp1252"),
                  "\u008F" => "\x8F".force_encoding("cp1252"),
                  "\u0090" => "\x90".force_encoding("cp1252"),
                  "\u009D" => "\x9D".force_encoding("cp1252")
                }).encode("utf-8")
  end
end
