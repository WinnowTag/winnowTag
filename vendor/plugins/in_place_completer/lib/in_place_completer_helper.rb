module InPlaceCompleterHelper

  # Helper for including in place editor with completion facilities to your
  # page. This method generates a JavaScript include call. You will
  # need to include defaults for the in_place_completer to work, though.
  def in_place_completer_include
    javascript_include_tag 'in_place_completer'
  end

  # Makes an HTML element specified by the DOM ID +field_id+ become an in-place
  # editor of a property, with local completion through the values provided.
  #
  # A form is automatically created and displayed when the user clicks the element,
  # something like this:
  #   <form id="myElement-in-place-edit-form" target="specified url">
  #     <input name="value" text="The content of myElement"/>
  #     <input type="submit" value="ok"/>
  #     <a onclick="javascript to cancel the editing">cancel</a>
  #   </form>
  # 
  # The form is serialized and sent to the server using an AJAX call, the action on
  # the server should process the value and return the updated value in the body of
  # the reponse. The element will automatically be updated with the changed value
  # (as returned from the server).
  # 
  # +completion+ should be a list of strings, detailing the available values.
  # If some part of the string should be displayed but not used for completion
  # you can wrap it in a span with class 'informal'.
  #   
  # Required +options+ are:
  # <tt>:url</tt>::       Specifies the url where the updated value should
  #                       be sent after the user presses "ok".
  # 
  # Addtional +options+ are:
  # <tt>:rows</tt>::              Number of rows (more than 1 will use a TEXTAREA)
  # <tt>:cols</tt>::              Number of characters the text input should span (works for both INPUT and TEXTAREA)
  # <tt>:size</tt>::              Synonym for :cols when using a single line text input.
  # <tt>:cancel_text</tt>::       The text on the cancel link. (default: "cancel")
  # <tt>:save_text</tt>::         The text on the save link. (default: "ok")
  # <tt>:loading_text</tt>::      The text to display when submitting to the server (default: "Saving...")
  # <tt>:external_control</tt>::  The id of an external control used to enter edit mode.
  # <tt>:load_text_url</tt>::     URL where initial value of editor (content) is retrieved.
  # <tt>:options</tt>::           Pass through options to the AJAX call (see prototype's Ajax.Updater)
  # <tt>:with</tt>::              JavaScript snippet that should return what is to be sent
  #                               in the AJAX call, +form+ is an implicit parameter
  # <tt>:script</tt>::            Instructs the in-place editor to evaluate the remote JavaScript response (default: false)
  # <tt>:ok_button</tt>::         Should an okButton be rendered? (default: true)
  # <tt>:cancel_link</tt>::       Should a cancel link be rendered? (default: true)  
  # <tt>:saving_text</tt>::       Text displayed during saving. (default: "Saving...")  
  # <tt>:click_to_edit_text</tt>:: The hover text to display over the field
  # <tt>:highlight_color</tt>::    The color to highlight the element with when doing a mouseover     
  # <tt>:highlight_end_color</tt>:: The color that is the end of the fading from the highlightcolor (if there is another background than white)
  #
  #
  # Addtional +completion_options+ are:
  # <tt>:update</tt>::    Specifies the DOM ID of the element whose 
  #                       innerHTML should be updated with the autocomplete
  #                       entries returned by the AJAX request. 
  #                       Defaults to field_id + '_auto_complete'
  # <tt>:with</tt>::      A JavaScript expression specifying the
  #                       parameters for the XMLHttpRequest. This defaults
  #                       to 'fieldname=value'.
  # <tt>:frequency</tt>:: Determines the time to wait after the last keystroke
  #                       for the AJAX request to be initiated.
  # <tt>:indicator</tt>:: Specifies the DOM ID of an element which will be
  #                       displayed while autocomplete is running.
  # <tt>:tokens</tt>::    A string or an array of strings containing
  #                       separator tokens for tokenized incremental 
  #                       autocompletion. Example: <tt>:tokens => ','</tt> would
  #                       allow multiple autocompletion entries, separated
  #                       by commas.
  # <tt>:min_chars</tt>:: The minimum number of characters that should be
  #                       in the input field before an Ajax call is made
  #                       to the server.
  # <tt>:on_hide</tt>::   A Javascript expression that is called when the
  #                       autocompletion div is hidden. The expression
  #                       should take two variables: element and update.
  #                       Element is a DOM element for the field, update
  #                       is a DOM element for the div from which the
  #                       innerHTML is replaced.
  # <tt>:on_show</tt>::   Like on_hide, only now the expression is called
  #                       then the div is shown.
  # <tt>:after_update_element</tt>::   A Javascript expression that is called when the
  #                       user has selected one of the proposed values. 
  #                       The expression should take two variables: element and value.
  #                       Element is a DOM element for the field, value
  #                       is the value selected by the user.
  # <tt>:select</tt>::    Pick the class of the element from which the value for 
  #                       insertion should be extracted. If this is not specified,
  #                       the entire element is used.
  #
  def in_place_editor_local_completer(field_id, completions, options = { }, completion_options = { })
    function =  "new Ajax.InPlaceEditor.LocalCompletion("
    function << "'#{field_id}', "
    function << "'#{completion_options[:update]}', "
    function << "#{array_or_string_for_javascript(completions)}, "
    function << "'#{url_for(options[:url])}'"


    js_options = {}
    js_options['okButton'] = options[:ok_button] if options[:ok_button]
    js_options['cancelLink'] = options[:cancel_link] if options[:cancel_link]
    js_options['savingText'] = %('#{options[:saving_text]}') if options[:saving_text]
    js_options['clickToEditText'] = %('#{options[:click_to_edit_text]}') if options[:click_to_edit_text]
    js_options['highlightcolor'] = %('#{options[:highlight_color]}') if options[:highlight_color]
    js_options['highlightendcolor'] = %('#{options[:highlight_end_color]}') if options[:highlight_end_color]

    js_options['cancelText'] = %('#{options[:cancel_text]}') if options[:cancel_text]
    js_options['okText'] = %('#{options[:save_text]}') if options[:save_text]
    js_options['loadingText'] = %('#{options[:loading_text]}') if options[:loading_text]
    js_options['rows'] = options[:rows] if options[:rows]
    js_options['cols'] = options[:cols] if options[:cols]
    js_options['size'] = options[:size] if options[:size]
    js_options['externalControl'] = "'#{options[:external_control]}'" if options[:external_control]
    js_options['loadTextURL'] = "'#{url_for(options[:load_text_url])}'" if options[:load_text_url]
    js_options['ajaxOptions'] = options[:options] if options[:options]
    js_options['evalScripts'] = options[:script] if options[:script]
    js_options['callback']   = "function(form) { return #{options[:with]} }" if options[:with]
    function << (', ' + options_for_javascript(js_options)) unless js_options.empty?

    js_options_c = {}
    js_options_c[:tokens] = array_or_string_for_javascript(completion_options[:tokens]) if completion_options[:tokens]
    js_options_c[:callback]   = "function(element, value) { return #{completion_options[:with]} }" if completion_options[:with]
    js_options_c[:indicator]  = "'#{completion_options[:indicator]}'" if completion_options[:indicator]
    js_options_c[:select]     = "'#{completion_options[:select]}'" if completion_options[:select]
    js_options_c[:frequency]  = "#{completion_options[:frequency]}" if completion_options[:frequency]

    { :after_update_element => :afterUpdateElement,
      :on_show => :onShow, :on_hide => :onHide, :min_chars => :minChars }.each do |k,v|
      js_options_c[v] = completion_options[k] if completion_options[k]
    end
    function << (', ' + options_for_javascript(js_options_c)) unless js_options_c.empty?
    function << ')'

    javascript_tag(function)
  end

  # Makes an HTML element specified by the DOM ID +field_id+ become an in-place
  # editor of a property, with completion from the server, as the usual autocompleter.
  #
  # A form is automatically created and displayed when the user clicks the element,
  # something like this:
  #   <form id="myElement-in-place-edit-form" target="specified url">
  #     <input name="value" text="The content of myElement"/>
  #     <input type="submit" value="ok"/>
  #     <a onclick="javascript to cancel the editing">cancel</a>
  #   </form>
  # 
  # The form is serialized and sent to the server using an AJAX call, the action on
  # the server should process the value and return the updated value in the body of
  # the reponse. The element will automatically be updated with the changed value
  # (as returned from the server).
  # 
  # This function expects that the called action returns a HTML <ul> list,
  # or nothing if no entries should be displayed for autocompletion.
  #
  # You'll probably want to turn the browser's built-in autocompletion off,
  # so be sure to include a autocomplete="off" attribute with your text
  # input field.
  #
  # Required +options+ are:
  # <tt>:url</tt>::       Specifies the url where the updated value should
  #                       be sent after the user presses "ok".
  # 
  # Addtional +options+ are:
  # <tt>:rows</tt>::              Number of rows (more than 1 will use a TEXTAREA)
  # <tt>:cols</tt>::              Number of characters the text input should span (works for both INPUT and TEXTAREA)
  # <tt>:size</tt>::              Synonym for :cols when using a single line text input.
  # <tt>:cancel_text</tt>::       The text on the cancel link. (default: "cancel")
  # <tt>:save_text</tt>::         The text on the save link. (default: "ok")
  # <tt>:loading_text</tt>::      The text to display when submitting to the server (default: "Saving...")
  # <tt>:external_control</tt>::  The id of an external control used to enter edit mode.
  # <tt>:load_text_url</tt>::     URL where initial value of editor (content) is retrieved.
  # <tt>:options</tt>::           Pass through options to the AJAX call (see prototype's Ajax.Updater)
  # <tt>:with</tt>::              JavaScript snippet that should return what is to be sent
  #                               in the AJAX call, +form+ is an implicit parameter
  # <tt>:script</tt>::            Instructs the in-place editor to evaluate the remote JavaScript response (default: false)
  # <tt>:ok_button</tt>::         Should an okButton be rendered? (default: true)
  # <tt>:cancel_link</tt>::       Should a cancel link be rendered? (default: true)  
  # <tt>:saving_text</tt>::       Text displayed during saving. (default: "Saving...")  
  # <tt>:click_to_edit_text</tt>:: The hover text to display over the field
  # <tt>:highlight_color</tt>::    The color to highlight the element with when doing a mouseover     
  # <tt>:highlight_end_color</tt>:: The color that is the end of the fading from the highlightcolor (if there is another background than white)
  #
  #
  # Required +completion_options+ are:
  # <tt>:url</tt>::       URL to call for autocompletion results
  #                       in url_for format.
  # 
  # Addtional +completion_options+ are:
  # <tt>:update</tt>::    Specifies the DOM ID of the element whose 
  #                       innerHTML should be updated with the autocomplete
  #                       entries returned by the AJAX request. 
  #                       Defaults to field_id + '_auto_complete'
  # <tt>:with</tt>::      A JavaScript expression specifying the
  #                       parameters for the XMLHttpRequest. This defaults
  #                       to 'fieldname=value'.
  # <tt>:frequency</tt>:: Determines the time to wait after the last keystroke
  #                       for the AJAX request to be initiated.
  # <tt>:indicator</tt>:: Specifies the DOM ID of an element which will be
  #                       displayed while autocomplete is running.
  # <tt>:tokens</tt>::    A string or an array of strings containing
  #                       separator tokens for tokenized incremental 
  #                       autocompletion. Example: <tt>:tokens => ','</tt> would
  #                       allow multiple autocompletion entries, separated
  #                       by commas.
  # <tt>:min_chars</tt>:: The minimum number of characters that should be
  #                       in the input field before an Ajax call is made
  #                       to the server.
  # <tt>:on_hide</tt>::   A Javascript expression that is called when the
  #                       autocompletion div is hidden. The expression
  #                       should take two variables: element and update.
  #                       Element is a DOM element for the field, update
  #                       is a DOM element for the div from which the
  #                       innerHTML is replaced.
  # <tt>:on_show</tt>::   Like on_hide, only now the expression is called
  #                       then the div is shown.
  # <tt>:after_update_element</tt>::   A Javascript expression that is called when the
  #                       user has selected one of the proposed values. 
  #                       The expression should take two variables: element and value.
  #                       Element is a DOM element for the field, value
  #                       is the value selected by the user.
  # <tt>:select</tt>::    Pick the class of the element from which the value for 
  #                       insertion should be extracted. If this is not specified,
  #                       the entire element is used.
  #
  def in_place_editor_completer(field_id, options = { }, completion_options = { })
    function =  "new Ajax.InPlaceEditor.Completion("
    function << "'#{field_id}', "
    function << "'#{completion_options[:update]}', "
    function << "'#{completion_options[:url]}', "
    function << "'#{url_for(options[:url])}'"


    js_options = {}
    js_options['paramName'] = options[:param_name] if options[:param_name]
    js_options['okButton'] = options[:ok_button] if options[:ok_button]
    js_options['cancelLink'] = options[:cancel_link] if options[:cancel_link]
    js_options['savingText'] = %('#{options[:saving_text]}') if options[:saving_text]
    js_options['clickToEditText'] = %('#{options[:click_to_edit_text]}') if options[:click_to_edit_text]
    js_options['highlightcolor'] = %('#{options[:highlight_color]}') if options[:highlight_color]
    js_options['highlightendcolor'] = %('#{options[:highlight_end_color]}') if options[:highlight_end_color]

    js_options['cancelText'] = %('#{options[:cancel_text]}') if options[:cancel_text]
    js_options['okText'] = %('#{options[:save_text]}') if options[:save_text]
    js_options['loadingText'] = %('#{options[:loading_text]}') if options[:loading_text]
    js_options['rows'] = options[:rows] if options[:rows]
    js_options['cols'] = options[:cols] if options[:cols]
    js_options['size'] = options[:size] if options[:size]
    js_options['externalControl'] = "'#{options[:external_control]}'" if options[:external_control]
    js_options['loadTextURL'] = "'#{url_for(options[:load_text_url])}'" if options[:load_text_url]
    js_options['ajaxOptions'] = options[:options] if options[:options]
    js_options['evalScripts'] = options[:script] if options[:script]
    js_options['callback']   = "function(form) { return #{options[:with]} }" if options[:with]
    js_options['formSubmit'] = options[:form_submit] if options[:form_submit]
    js_options['onSubmit'] = options[:submit] if options[:submit]
    function << (', ' + options_for_javascript(js_options)) unless js_options.empty?

    js_options_c = {}
    js_options_c[:tokens] = array_or_string_for_javascript(completion_options[:tokens]) if completion_options[:tokens]
    js_options_c[:callback]   = "function(element, value) { return #{completion_options[:with]} }" if completion_options[:with]
    js_options_c[:indicator]  = "'#{completion_options[:indicator]}'" if completion_options[:indicator]
    js_options_c[:select]     = "'#{completion_options[:select]}'" if completion_options[:select]
    js_options_c[:frequency]  = "#{completion_options[:frequency]}" if completion_options[:frequency]

    { :after_update_element => :afterUpdateElement,
      :on_show => :onShow, :on_hide => :onHide, :min_chars => :minChars }.each do |k,v|
      js_options_c[v] = completion_options[k] if completion_options[k]
    end
    function << (', ' + options_for_javascript(js_options_c)) unless js_options_c.empty?
    function << ')'

    javascript_tag(function)
  end

  # Renders the value of the specified object and method with in-place editing capabilities and autocompletion from the server.
  # If no :url is provided in +completion_options+, a new url with :action "auto_complete_for_#{object}_#{method}" will be 
  # used.
  def in_place_completing_editor_field(object, method, tag_options = {}, in_place_editor_options = {}, completion_options = {})
    tag = ::ActionView::Helpers::InstanceTag.new(object, method, self)
    tag_options = {:tag => "span", :id => "#{object}_#{method}_#{tag.object.id}_in_place_editor", :class => "in_place_editor_field"}.merge!(tag_options)
    in_place_editor_options[:url] = in_place_editor_options[:url] || url_for({ :action => "set_#{object}_#{method}", :id => tag.object.id })
    completion_options[:url] ||= url_for({ :action => "auto_complete_for_#{object}_#{method}"})
    completion_options[:update] ||=  "#{object}_#{method}_auto_complete"
    (completion_options[:skip_style] ? "" : auto_complete_stylesheet) +
      tag.to_content_tag(tag_options.delete(:tag), tag_options) +
      content_tag("div", "", :id => completion_options[:update], :class => "auto_complete") +
      in_place_editor_completer(tag_options[:id], in_place_editor_options, completion_options)
  end

  # Renders the value of the specified object and method with in-place editing capabilities and local autocompletion
  # using the values provided in completions.
  def in_place_local_completing_editor_field(object, method, completions, tag_options = {}, in_place_editor_options = {}, completion_options = {})
    tag = ::ActionView::Helpers::InstanceTag.new(object, method, self)
    tag_options = {:tag => "span", :id => "#{object}_#{method}_#{tag.object.id}_in_place_editor", :class => "in_place_editor_field"}.merge!(tag_options)
    in_place_editor_options[:url] = in_place_editor_options[:url] || url_for({ :action => "set_#{object}_#{method}", :id => tag.object.id })
    completion_options[:update] ||=  "#{object}_#{method}_auto_complete"
    (completion_options[:skip_style] ? "" : auto_complete_stylesheet) +
      tag.to_content_tag(tag_options.delete(:tag), tag_options) +
      content_tag("div", "", :id => completion_options[:update], :class => "auto_complete") +
      in_place_editor_local_completer(tag_options[:id], completions, in_place_editor_options, completion_options)
  end

  private
  def auto_complete_stylesheet
    content_tag("style", <<-EOT
                div.auto_complete {
                  width: 350px;
                  background: #fff;
                }
                div.auto_complete ul {
                  border:1px solid #888;
                  margin:0;
                  padding:0;
                  width:100%;
                  list-style-type:none;
                }
                div.auto_complete ul li {
                  margin:0;
                  padding:0px;
                }
                div.auto_complete ul li.selected {
                  background-color: #bbb;
                }
                div.auto_complete ul strong.highlight {
                  color: #800;
                    margin:0;
                  padding:0;
                }
                EOT
                )
  end
end
