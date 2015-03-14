module InPlaceMacrosHelper
  # Makes an HTML element specified by the DOM ID +field_id+ become an in-place
  # editor of a property.
  #
  # A form is automatically created and displayed when the user clicks the element,
  # something like this:
  #   
# # # cancel #

  # 
  # The form is serialized and sent to the server using an AJAX call, the action on
  # the server should process the value and return the updated value in the body of
  # the reponse. The element will automatically be updated with the changed value
  # (as returned from the server).
  # 
  # Required +options+ are:
  # :url::       Specifies the url where the updated value should
  #                       be sent after the user presses "ok".
  # 
  # Addtional +options+ are:
  # :rows::              Number of rows (more than 1 will use a TEXTAREA)
  # :cols::              Number of characters the text input should span (works for both INPUT and TEXTAREA)
  # :size::              Synonym for :cols when using a single line text input.
  # :cancel_text::       The text on the cancel link. (default: "cancel")
  # :save_text::         The text on the save link. (default: "ok")
  # :loading_text::      The text to display while the data is being loaded from the server (default: "Loading...")
  # :saving_text::       The text to display when submitting to the server (default: "Saving...")
  # :external_control::  The id of an external control used to enter edit mode.
  # :load_text_url::     URL where initial value of editor (content) is retrieved.
  # :options::           Pass through options to the AJAX call (see prototype's Ajax.Updater)
  # :with::              JavaScript snippet that should return what is to be sent
  #                               in the AJAX call, +form+ is an implicit parameter
  # :script::            Instructs the in-place editor to evaluate the remote JavaScript response (default: false)
  # :click_to_edit_text::The text shown during mouseover the editable text (default: "Click to edit")

  # Scriptaculous Usage: new Ajax.InPlaceEditor( element, url, [options]);
  def in_place_editor(field_id, options = {})
    function =  "new Ajax.InPlaceEditor("
    function << "'#{field_id}', "
    function << "'#{url_for(options[:url])}'"

    #CHANGED: Added to allow plugin to work with Rails 2 session forgery protection
    if protect_against_forgery? 
      options[:with] ||= "Form.serialize(form)" 
      options[:with] += " + '&authenticity_token=' + encodeURIComponent('#{form_authenticity_token}')" 
    end 
    #End CHANGE

    js_options = {}
    js_options['cancelText'] = %('#{options[:cancel_text]}') if options[:cancel_text]
    js_options['okText'] = %('#{options[:save_text]}') if options[:save_text]
    js_options['loadingText'] = %('#{options[:loading_text]}') if options[:loading_text]
    js_options['savingText'] = %('#{options[:saving_text]}') if options[:saving_text]
    js_options['rows'] = options[:rows] if options[:rows]
    js_options['cols'] = options[:cols] if options[:cols]
    js_options['size'] = options[:size] if options[:size]
    js_options['externalControl'] = "'#{options[:external_control]}'" if options[:external_control]
    js_options['loadTextURL'] = "'#{url_for(options[:load_text_url])}'" if options[:load_text_url]        
    js_options['ajaxOptions'] = options[:options] if options[:options]
    #CHANGED: To bring in line with current scriptaculous usage
    js_options['htmlResponse'] = !options[:script] if options[:script]
    js_options['callback']   = "function(form) { return #{options[:with]} }" if options[:with]
    js_options['clickToEditText'] = %('#{options[:click_to_edit_text]}') if options[:click_to_edit_text]
    js_options['textBetweenControls'] = %('#{options[:text_between_controls]}') if options[:text_between_controls]
    function << (', ' + options_for_javascript(js_options)) unless js_options.empty?

    function << ')'

    javascript_tag(function)
  end

  # Renders the value of the specified object and method with in-place editing capabilities.
  def in_place_editor_field(object, method, tag_options = {}, in_place_editor_options = {})
    tag = ::ActionView::Helpers::InstanceTag.new(object, method, self)
    tag_options = {:tag => "span", :id => "#{object}_#{method}_#{tag.object.id}_in_place_editor", :class => "in_place_editor_field"}.merge!(tag_options)
    in_place_editor_options[:url] = in_place_editor_options[:url] || url_for({ :action => "set_#{object}_#{method}", :id => tag.object.id })
    tag.to_content_tag(tag_options.delete(:tag), tag_options) +
    in_place_editor(tag_options[:id], in_place_editor_options)
  end

  #CHANGE: The following two methods were added to allow in place editing with a select field instead of a text field.
  #         For more info visit: http://www.thetacom.info/2008/03/21/rails-in-place-editing-plugin-w-selection/
  # Scriptaculous Usage: new Ajax.InPlaceCollectionEditor( element, url, { collection: [array], [moreOptions] } );
  def in_place_collection_editor(field_id, options = {})
    function =  "new Ajax.InPlaceCollectionEditor("
    function << "'#{field_id}', "
    function << "'#{url_for(options[:url])}'"

    #CHANGED: Added to allow plugin to work with Rails 2 session forgery protection
    if protect_against_forgery? 
      options[:with] ||= "Form.serialize(form)" 
      options[:with] += " + '&authenticity_token=' + encodeURIComponent('#{form_authenticity_token}')" 
    end 
    #end CHANGE

    js_options = {}
    js_options['collection'] = %(#{options[:collection]})
    js_options['cancelText'] = %('#{options[:cancel_text]}') if options[:cancel_text]
    js_options['okText'] = %('#{options[:save_text]}') if options[:save_text]
    js_options['loadingText'] = %('#{options[:loading_text]}') if options[:loading_text]
    js_options['savingText'] = %('#{options[:saving_text]}') if options[:saving_text]
    js_options['rows'] = options[:rows] if options[:rows]
    js_options['cols'] = options[:cols] if options[:cols]
    js_options['size'] = options[:size] if options[:size]
    js_options['externalControl'] = "'#{options[:external_control]}'" if options[:external_control]
    js_options['loadTextURL'] = "'#{url_for(options[:load_text_url])}'" if options[:load_text_url]        
    js_options['ajaxOptions'] = options[:options] if options[:options]
    #CHANGED: To bring in line with current scriptaculous usage
    js_options['htmlResponse'] = !options[:script] if options[:script]
    js_options['callback']   = "function(form) { return #{options[:with]} }" if options[:with]
    js_options['clickToEditText'] = %('#{options[:click_to_edit_text]}') if options[:click_to_edit_text]
    js_options['textBetweenControls'] = %('#{options[:text_between_controls]}') if options[:text_between_controls]
    function << (', ' + options_for_javascript(js_options)) unless js_options.empty?

    function << ')'

    javascript_tag(function)
  end

  # Renders the value of the specified object and method with in-place select capabilities.
  def in_place_editor_select_field(object, method, tag_options = {}, in_place_editor_options = {})
    tag = ::ActionView::Helpers::InstanceTag.new(object, method, self)
    tag_options = {:tag => "span", :id => "#{object}_#{method}_#{tag.object.id}_in_place_editor", :class => "in_place_editor_field"}.merge!(tag_options)
    in_place_editor_options[:url] = in_place_editor_options[:url] || url_for({ :action => "set_#{object}_#{method}", :id => tag.object.id })
    tag.to_content_tag(tag_options.delete(:tag), tag_options) +
    in_place_collection_editor(tag_options[:id], in_place_editor_options)
  end
end