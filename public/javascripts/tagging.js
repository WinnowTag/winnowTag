/* 
Copyright (c) 2007 The Kaphan Foundation

Possession of a copy of this file grants no permission or license
to use, modify, or create derivate works.

Please contact info@peerworks.org for further information.
*/

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

function add_tagging(taggable_id, tag_name, tagging_type) {
  if( tag_name.match(/^\s*$/) ) { return; }

  var match = tag_name.match(/^Create Tag: '(.+)'$/);
  if(match) { tag_name = match[1]; }

  var tag_control = $("tag_control_for_" + tag_name + "_on_" + taggable_id);
  var url = '/taggings/create';
  var parameters = {
    "tagging[feed_item_id]": taggable_id.match(/(\d+)$/)[1],
    "tagging[tag]": tag_name,
    "tagging[strength]": tagging_type == "positive" ? 1 : 0
  }
  
  var other_tagging_type = tagging_type == "positive" ? "negative" : "positive";
  
  if (!tag_control) {
    add_tag_control(taggable_id, tag_name);
  } else if (tag_control.hasClassName(other_tagging_type)) {
    tag_control.removeClassName(other_tagging_type);
    tag_control.addClassName(tagging_type);
  } else if (tag_control.hasClassName('classifier')) {
    tag_control.addClassName(tagging_type); 
  } else {
    new ErrorMessage("Invalid tag control state: " + tag_control.classNames().toArray().join(' '));
  }
  
  sendTagRequest(url, parameters);
}

function remove_tagging(taggable_id, tag_name) {
  if( tag_name.match(/^\s*$/) ) { return; }

  var tag_control = $("tag_control_for_" + tag_name + "_on_" + taggable_id);
  var url = '/taggings/destroy';
  var parameters = {
    "tagging[feed_item_id]": taggable_id.match(/(\d+)$/)[1],
    "tagging[tag]": tag_name,
  }
  
  if (tag_control) {
    tag_control.removeClassName('positive');
    tag_control.removeClassName('negative');
    if(!tag_control.match('.classifier')) {
      remove_tag_control(taggable_id, tag_name); 
    }
  } else {
    new ErrorMessage("Invalid tag control state: " + tag_control.classNames().toArray().join(' '));
  }

  sendTagRequest(url, parameters);  
}

function sendTagRequest(url, parameters) {
  new Ajax.Request(url, {parameters: $H(parameters).toQueryString(),
    method: 'post',
    onFailure: function(transport) {
      new ErrorMessage("Error contacting server.  You're changes have not been saved.");
    }
  });
}

function add_tag_control(taggable_id, tag) {
  if (tag == null || tag == '') return false;
  var tag_controls = $('tag_controls_' + taggable_id);
  var tag_control_id = 'tag_control_for_' + tag + '_on_' + taggable_id;
  var tag_control = '<li id="' + tag_control_id + '" class="positive" style="display: none;" onmouseover="set_tag_status(this, \'' + escape_javascript(tag) + '\');">' + 
    '<span class="name">' + tag + '</span>' + 
    '<span class="controls">' +
      '<span class="status"></span> ' +
      '<a class="positive" onclick="add_tagging(\'' + taggable_id + '\', \'' + escape_javascript(tag) + '\', \'positive\'); return false;" href="#">Make Positive</a> ' + 
      '<a class="negative" onclick="add_tagging(\'' + taggable_id + '\', \'' + escape_javascript(tag) + '\', \'negative\'); return false;" href="#">Make Negative</a> ' + 
      '<a class="remove" onclick="remove_tagging(\'' + taggable_id + '\', \'' + escape_javascript(tag) + '\'); return false;" href="#">Remove Training</a> ' + 
    '</span>' +
  '</li> ';
  insert_in_order(tag_controls, "li", "span.name", tag_control, tag);
  Effect.Appear(tag_control_id);
}

function remove_tag_control(taggable_id, tag) {
  if (tag == null || tag == '') return false;  
  var tag_control_id = 'tag_control_for_' + tag + '_on_' + taggable_id;
  Effect.Fade(tag_control_id, { afterFinish: function() { Element.remove(tag_control_id) } });
}

function set_tag_status(tag, tag_name, classifier_strength, user) {
  tag = $(tag);
  var status = "";
  
  if (tag.match('.negative')) {
    status = "Negative training";
  } else if (tag.match('.positive')) {
    status = "Positive training";
  } else if (tag.match('.classifier')) {
    status = "Automatic tag (" + classifier_strength + ")";
  }
  
  if(user) {
    status += " (from " + user + ")"
  }
  
  tag.down(".status").update(status);
  tag.down(".controls").style.left = "-" + (tag.down(".controls").getWidth() - tag.down(".name").getWidth()) / 2 + "px";
}
