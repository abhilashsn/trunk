#  Description: Module responsible to add rake tasks to delayed job
require "delayed_task"
module DelayedTask
  class << self
    include Rake::DSL if defined?(Rake::DSL)
    def add_delayed_tasks
      Rake::Task.tasks.each do |task|
        task "delay:#{task.name}", *task.arg_names << :queue do |t, args|
          options = args.to_hash
          queue = options.delete(:queue)
          queue = set_queue task.name
          Rake::Task["environment"].invoke
          values = options.values.empty? ? "" : "[" + options.values.collect{|v| "'#{v}'"}.join(",") + "]"
          invocation = task.name + values
          puts invocation
          if queue
            Delayed::Job.enqueue DelayedTask::PerformableTask.new(invocation), :queue => queue
          else
            Delayed::Job.enqueue DelayedTask::PerformableTask.new(invocation)
          end

          puts "Enqueued job: rake #{invocation}"
        end
      end
    end
    
    #This method is responsible to set the queue name as per the rake task name
    def set_queue task_name
      batch_loading_task_names = ["new_input:import_batch_file", 
        "new_input:execute_import_batch_file_script",
        "input:create_plans"]
      ocr_task_names = ["ocr:parse_ocr_xml"]
      if batch_loading_task_names.include?(task_name)
        "batch_loading"
      elsif ocr_task_names.include?(task_name)
        "ocr_loading"
      else
        ""
      end 
    end
  end
end

DelayedTask.add_delayed_tasks
