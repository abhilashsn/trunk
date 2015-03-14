namespace :client_h_output do
  task :generate_text_output, [:batch_id_string]  => [:environment]  do |t, args|
    p args.batch_id_string
    Runner.text_output_generator(args.batch_id_string)
  end
end