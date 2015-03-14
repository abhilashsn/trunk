class FacilityLookupFieldsController < ApplicationController
  layout 'standard'
  require_role ["admin","supervisor","manager"]
  in_place_edit_with_validation_for :facility_lookup_field, :name

  #This is for listing TAT Comments from facility_lookup_field table.
  def show_tat_comments
    @facility_lookup_fields = FacilityLookupField.tat_comments
    render :layout => "standard_inline_edit"
  end

  #This is for creating TAT Comments in facility_lookup_field table.
  def create_tat_comment
    flash[:notice] = nil
    tat_comment = params[:name].strip unless params[:name].blank?

    unless tat_comment.blank?
      facility_lookup_field = FacilityLookupField.create( :name => tat_comment,
        :lookup_type => "TAT Comment" )
    end

    unless facility_lookup_field.blank?
      flash[:notice] = "TAT Comment created successfully."
    else
      flash[:notice] = "Failed creating TAT Comment."
    end
    
    redirect_to :action =>'show_tat_comments'
  end

  #This is for deleting TAT Comments.
  def delete_tat_comment
    flash[:notice] = nil
    tat_comment = FacilityLookupField.find(params[:id])

    unless tat_comment.blank?
      tat_comment.destroy
      flash[:notice] = "TAT Comment deleted successfully."
    else
      flash[:notice] = "Failed deleting TAT Comment."
    end
    
    redirect_to :action =>'show_tat_comments'
  end

end
