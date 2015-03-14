module InPlaceEditing
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Example:
  #
  #   # Controller
  #   class BlogController < ApplicationController
  #     in_place_edit_for :post, :title
  #   end
  #
  #   # View
  #   <%= in_place_editor_field :post, 'title' %>
  #
  module ClassMethods
    def in_place_edit_for(object, attribute, options = {})
      define_method("set_#{object}_#{attribute}") do
        @item = object.to_s.camelize.constantize.find(params[:id])
        @item.update_attribute(attribute, params[:value])
        render :js => "$('#{object}_#{attribute}_#{params[:id]}_in_place_editor').innerHTML = '#{@item.send(attribute).to_s}';"
      end
    end

    def in_place_sp_edit_for(object, attribute, options = {})
      define_method("set_#{object}_#{attribute}") do
        @item = object.to_s.camelize.constantize.find(params[:id])
        if (@item.update_attributes(attribute=>params[:value]))
          render :text => "Element.update('#{object}_#{attribute}_#{params[:id]}_in_place_editor',\"#{@item.send(attribute)}\")", :content_type => 'text/javascript'
        else
          err_msgs = 'alert("'+@item.errors.full_messages.join('\n')+'");'
          @item.reload
          err_msgs << "Element.update('#{object}_#{attribute}_#{params[:id]}_in_place_editor',\"#{@item.send(attribute)}\")"
          render :text => err_msgs, :content_type => 'text/javascript'
        end
      end
    end
	    
    def in_place_sp_edit_text_area_for(object, attribute, options = {})
      define_method("set_#{object}_#{attribute}") do
        @item = object.to_s.camelize.constantize.find(params[:id])
        if (@item.update_attributes(attribute=>params[:value]))
          out_text = Regexp.escape(@item.send(attribute)).gsub(/([\n\r'])/,'\\\\\1')
          render :text => "$('#{object}_#{attribute}_#{params[:id]}_in_place_editor').innerHTML= '#{out_text}' ", :content_type => 'text/javascript'
        else
          err_msgs = 'alert("'+@item.errors.full_messages.join('\n')+'");'
          @item.reload
          out_text = Regexp.escape(@item.send(attribute)).gsub(/([\n\r'])/,'\\\\\1')
          err_msgs << "Element.update('#{object}_#{attribute}_#{params[:id]}_in_place_editor','#{out_text}')"
          render :text => err_msgs, :content_type => 'text/javascript'
        end
      end
    end


  end
end
