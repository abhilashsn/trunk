class RemoveForeignKeyFromEraJobs < ActiveRecord::Migration
  def up
    execute "ALTER TABLE era_jobs
    DROP FOREIGN KEY FK_era_jobs_facility"
  end

  def down
    execute "ALTER TABLE era_jobs
    ADD CONSTRAINT FK_era_jobs_facility FOREIGN KEY (facility_id) REFERENCES facilities(id)"
  end
end
