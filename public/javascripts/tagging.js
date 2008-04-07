/* 
Copyright (c) 2007 The Kaphan Foundation

Possession of a copy of this file grants no permission or license
to use, modify, or create derivate works.

Please contact info@peerworks.org for further information.
*/

/* Javascript for Tagging interface */

function validate_tag_edit(original_name, new_name) {
  if (new_name == original_name) {
    new ErrorMessage("Can't rename a tag to the same name.");
    return false;
  } 
  
  if (new_name == "") {
    new ErrorMessage("Name can't be blank");
    return false;
  } 
  
  var merging = false;
  
  $$('span.in_place_editor_field').each(function(name) {
    if (name.innerHTML == new_name) {
      merging = true;
    }
  });
  
  if (merging) {
    return confirm("The tag name you have chosen already exists.\n\nMerge the two tags? ");
  } else {
    return true;    
  }  
}

function add_tag(taggable_id, tag_name, allow_remove) {
  if( tag_name.match(/^\s*$/) ) { return; }

  var match = tag_name.match(/^Create Tag: '(.+)'$/);
  if( match ) { tag_name = match[1]; }

  var tag_control = $("tag_control_for_" + tag_name + "_on_" + taggable_id);
  var url = '/taggings/create';
  var parameters = {};
  parameters["tagging[feed_item_id]"] = taggable_id.match(/(\d+)$/)[1];
  parameters["tagging[tag]"] = tag_name;
  parameters["tagging[strength]"] = "1";
  

  if (!tag_control) {
    add_tag_control(taggable_id, tag_name);
  } else if (tag_control.match('.negative')) {
    tag_control.removeClassName('negative');
    tag_control.addClassName('positive');
  } else if (tag_control.match('.positive')) {
    if(allow_remove) {
      tag_control.removeClassName('positive');
      url = '/taggings/destroy';
      if(!tag_control.match('.classifier')) {
        remove_tag_control(taggable_id, tag_name); 
      }
    }
  } else if (tag_control.match('.classifier')) {
    tag_control.addClassName('positive'); 
  } else {
    alert("Invalid tag control state: " + tag_control.classNames().toArray().join(' '));
  }

  sendTagRequest(url, parameters);
}

function remove_tag(taggable_id, tag_name) {
  if( tag_name.match(/^\s*$/) ) { return; }

  var tag_control = $("tag_control_for_" + tag_name + "_on_" + taggable_id);
  var url = '/taggings/create';
  var parameters = {};
  parameters["tagging[feed_item_id]"] = taggable_id.match(/(\d+)$/)[1];
  parameters["tagging[tag]"] = tag_name;
  parameters["tagging[strength]"] = "0";
  

  if (tag_control.match('.positive')) {
    tag_control.removeClassName('positive');
    tag_control.addClassName('negative');
  } else if (tag_control.match('.negative')) {
    tag_control.removeClassName('negative');
    url = '/taggings/destroy';
    if(!tag_control.match('.classifier')) {
      remove_tag_control(taggable_id, tag_name); 
    }
  } else if (tag_control.match('.classifier')) {
    tag_control.addClassName('negative'); 
  } else {
    alert("Invalid tag control state: " + tag_control.classNames().toArray().join(' '));
  }

  sendTagRequest(url, parameters);
}


/** Sends the tag request to the server.
 */
function sendTagRequest(url, parameters) {
  new Ajax.Request(url, {parameters: $H(parameters).toQueryString(),
    method: 'post',
    onFailure: function(transport) {
      alert("Error contacting server.  You're changes have not been saved.");
    }
  });
}

/** Add a tag control to the tagging interface for an item.
 *
 * = Parameters
 *
 * * taggable_id the item id
 * * tag The tag to add a control for.
 */
function add_tag_control(taggable_id, tag) {
  if (tag == null || tag == '') return false;
  var tag_controls = $('tag_controls_' + taggable_id);
  var tag_control_id = 'tag_control_for_' + tag + '_on_' + taggable_id;
  var tag_control = '<li id="' + tag_control_id + '" class="positive" style="display: none;" onmouseover="show_tag_tooltip(this, \'' + escape_javascript(tag) + '\'); show_tag_controls(this);">' + 
    '<span class="name">' + tag + '</span>' + 
    '<span class="controls" style="display:none">' +
      '<span class="add" onclick="add_tag(\'' + taggable_id + '\', \'' + escape_javascript(tag) + '\', true);" onmouseover="show_control_tooltip(this, $(this).up(\'li\'), \'' + escape_javascript(tag) + '\');"></span>' + 
      '<span class="remove" onclick="remove_tag(\'' + taggable_id + '\', \'' + escape_javascript(tag) + '\');" onmouseover="show_control_tooltip(this, $(this).up(\'li\'), \'' + escape_javascript(tag) + '\');"></span>' + 
    '</span>' +
  '</li> ';
  insert_in_order(tag_controls, "li", "span.name", tag_control, tag);
  Effect.Appear(tag_control_id);
}

function escape_javascript(string) {
  return string.replace(/'/g, '\\\'');
}

function remove_tag_control(taggable_id, tag) {
  if (tag == null || tag == '') return false;  
  var tag_control_id = 'tag_control_for_' + tag + '_on_' + taggable_id;
  Effect.Fade(tag_control_id, { afterFinish: function() { Element.remove(tag_control_id) } });
}

function show_control_tooltip(control, tag, tag_name) {
  var control_tooltip = "";
  
  if (tag.match('.negative')) {
    if(control.match(".add")) {
      control_tooltip = "Click if this is a very good example of " + tag_name;
    }  else if(control.match(".remove")) {
      control_tooltip = "Click to remove this negative example of " + tag_name;
    }
  } else if (tag.match('.positive')) {
    if(control.match(".add")) {
      control_tooltip = "Click to remove this positive example of " + tag_name;
    }  else if(control.match(".remove")) {
      control_tooltip = "Click if this is a bad example of " + tag_name;
    }
  } else if (tag.match('.classifier')) {
    if(control.match(".add")) {
      control_tooltip = "Click if this is a very good example of " + tag_name;
    }  else if(control.match(".remove")) {
      control_tooltip = "Click if this is a bad example of " + tag_name;
    }
  }

  control.setAttribute("title", control_tooltip);
}

function show_tag_tooltip(tag, tag_name, classifier_strength, user) {
  tag = $(tag);
  var tag_tooltip = "";
  
  if (tag.match('.negative')) {
    tag_tooltip = "Negative training example for Winnow";
  } else if (tag.match('.positive')) {
    tag_tooltip = "Positive training example for Winnow";
  } else if (tag.match('.classifier')) {
    tag_tooltip = "Winnow is " + classifier_strength +" sure this item fit your examples";
  }
  
  if(user) {
    tag_tooltip += " (from " + user + ")"
  }
  
  tag.setAttribute("title", tag_tooltip);
}

function show_tag_controls(tag) {
  tag = $(tag);
  var controls = tag.down('.controls');
  if(controls) {
    controls.show();
    tag.observe("mouseout", function() { controls.hide(); });
  }
}

Effect.ScrollToInDiv = Class.create();
Object.extend(Object.extend(Effect.ScrollToInDiv.prototype, Effect.Base.prototype), {
  initialize: function(container, element) {
    this.container = $(container);
    this.element = $(element);
    this.bottom_margin = (arguments[2] && arguments[2].bottom_margin) || 0;
    this.start(arguments[2] || {});      
  },
  setup: function() {
    var containerOffset = Position.cumulativeOffset(this.container);
    var offsets = Position.cumulativeOffset(this.element);
    if(this.options.offset) {
      offsets[1] += this.options.offset;
    }

    this.scrollStart = this.container.scrollTop;
     var top_of_element = offsets[1] - this.scrollStart;
     var top_of_container = containerOffset[1];
     var bottom_of_element = offsets[1] + this.element.getHeight() - this.scrollStart;
     var bottom_of_container = containerOffset[1] + this.container.getHeight();
     
     // If the item is above the top of the container, or the item is taller than the container, scroll to the top of the item
     if(top_of_element < top_of_container || this.element.getHeight() > this.container.getHeight()) {
       this.delta = top_of_element - top_of_container;

     // If the item is below the bottom of the container, scroll to the bottom of the item
     } else if(bottom_of_element > bottom_of_container) {
       this.delta = bottom_of_element - bottom_of_container + this.bottom_margin;

     } else {
       this.delta = 0;
     }
  },
  update: function(factor) {
    this.container.scrollTop = this.scrollStart + (factor * this.delta);
  }
});