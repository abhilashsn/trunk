module TwiceKeyingFieldsStatisticsHelper

  def legend_color(first_attempt_status)
    color = ''
    if first_attempt_status == true
      color = 'green'
    else
      color = 'orange'
    end
    color
  end
  
end
