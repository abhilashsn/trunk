Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.max_attempts = 2
Delayed::Worker.max_run_time = 72.hours
Delayed::Worker.read_ahead = 5