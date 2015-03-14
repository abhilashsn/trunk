module Input
#including the Parser Module
include Parser

class Reader #base class
  
  def self.create_file type
    if type == "BATCH"
      ReaderBatch.new 
    elsif type == "837"
      Reader837.new 
    end
  end
  
end

class Reader837 < Reader

  def load_file file,facility
  p "837 loading starts.........."
  @parser = Serializer837.new file,facility
  @parser.parse_837
  end

end

class ReaderBatch < Reader

  def load_file file
  p "Batch loading starts..........."
  @parser = SerializerBatch.new file
  @parser.image_import
  end
  
end
end
