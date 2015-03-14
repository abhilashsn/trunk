module DocumentuploadHelper

  def style_for_file_upload_div
    if @layout_needed == "false"
      "background-color:#ECE9D8;"
    else
      ""
    end
  end
end
