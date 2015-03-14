# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

module HlscHelper

  # CSS tooltip helper for batch status history
  def batch_tooltip(batch)
    result = "<center>BATCH(#{batch.batchid}) STATUS HISTORY<table><tr><th>USER</th><th>TIME</th><th>STATUS</th></tr>"
    batch.client_status_histories.each do |status_history| 
      result = result + "<tr><td>" + status_history.user + "</td><td>" + format_datetime(status_history.time) + "</td><td>" + status_history.status + "</td></tr>"
    end 
    result = result + "</table></center>"
    return result
  end
end
