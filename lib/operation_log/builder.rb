module OperationLog::Builder
  def self.build (&:block)
    generator = OperationLog::Generator.new
    generator.instance_eval(&block)
    generator
  end
end
