module HasDetails
  def self.included(base)
    base.extend(ClassMethods)
  end

  # HasDetails allows you to store a large amount of (optional) attributes for any model's instance in a
  # serialized column. It takes care of adding convenience methods to your model, and verifies that the
  # value being assigned is indeed (one of) the type(s) required for that attribute.
  #
  # Example:
  #
  #   class User << ActiveRecord::Base
  #     has_details :column => :extended_attributes,
  #                 :firstname => String,
  #                 :lastname => String,
  #                 :birthday => Date,
  #                 :gender => [:male, :female]
  #   end
  #
  #   john = User.find(1)
  #   john.birthday = 5.years.ago
  #   john.gender
  #   => :male
  module ClassMethods

    # Configuration options are:
    #
    # * +column+ - Specifies the column name to use for storing the serialized attributes. This column will automatically be set to serialize in Rails. The default value is :details.
    #
    # The rest of the configuration options is the set of attributes that will be saved in the +column+. Valid formats are:
    # * +:field => ClassName+ (values assigned to +field+ must be of class +ClassName+)
    # * +:field => [:symbol, :othersymbol]+  (values assigned to +field+ must be included in the array given)
    def has_details(*configuration)
      # configuration = { :column => :details}
      # configuration.update(options) if options.is_a?(Hash)
      column = "details"

      raise(ArgumentError, "You must be supply at least one field in the configuration hash") unless configuration.size > 0
      raise(Exception, "A #{column.inspect} column must be present in the database for this plugin.") unless column_names.include?(column.to_s)

      serialize column, Hash

      configuration.each do |f|
        {"coordinates" => Array, "page" => Fixnum, "confidence" => Fixnum, "data_origin"=>Fixnum, "ocr_output" => String, "ocr_state" => String}.each do |key, t|
          exception_code = "raise \"Assigned value must be a #{t.inspect}\" unless val.is_a?(#{t.inspect})"

          class_eval do "
            def #{f}_#{key}
              self.#{column.to_s} ||= {}
              self.#{column.to_s}[:#{f}_#{key}]
            end

            def #{f}_#{key}=(val)
              #{exception_code}

              self.#{column.to_s} ||= {}
              self.#{column.to_s}[:#{f}_#{key}] = val
            end
          " end
        end
      end
    end
  end

end
