#  Description: Module responsible to execute the rake tasks using delayed job
module DelayedTask
  class PerformableTask < Struct.new(:task)
    def perform
      system "rake #{task} >> log/delayed_task.log"
    end
  end
end
