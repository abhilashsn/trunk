class Output835::MeritMountainsideSingleStDocument < Output835::SingleStDocument
  
  # giving batch date instead of file generating date 
 def group_date
   checks.first.job.batch.date.strftime("%Y%m%d")
 end
 
end