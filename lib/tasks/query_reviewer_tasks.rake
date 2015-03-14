# desc "Explaining what the task does"
namespace :query_reviewer do
  desc "Create a default config/query_reviewer.yml"
  task :setup do
    FileUtils.copy(File.join(File.dirname(__FILE__), "..", "query_reviewer_defaults.yml"), File.join(Rails.root, "config", "query_reviewer.yml"))
  end  
end
