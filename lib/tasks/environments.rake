%w[development production staging].each do |env|
  desc "Runs the following task in the #{env} environment" 
  task env do
    Rails.env = ENV['Rails.env'] = env
  end
end

task :testing do
  Rails.env = ENV['Rails.env'] = 'test'
end

task :dev do
  Rake::Task["development"].invoke
end

task :prod do
  Rake::Task["production"].invoke
end