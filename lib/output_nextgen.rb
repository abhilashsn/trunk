module OutputNextgen
  require 'logger'

  def self.log
    Logger.new('output_logs/NextgenGeneration.log', 'daily')
  end

end
