// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
function add_tagging(taggable_id, tag_name, tagging_type) {
  if( tag_name.match(/^\s*$/) ) { return; }

  var match = tag_name.match(/^Create Tag: '(.+)'$/);
  if(match) { tag_name = match[1]; }

  var tag_control = $$('#' + taggable_id + ' .tag_control').detect(function(element) {
    return element.down(".name").innerHTML == tag_name;
  });
  var tag_information = $(taggable_id).down(".information");
  var url = '/taggings/create';
  var parameters = {
    "tagging[feed_item_id]": taggable_id.match(/(\d+)$/)[1],
    "tagging[tag]": tag_name,
    "tagging[strength]": tagging_type == "positive" ? 1 : 0
  };
  
  var other_tagging_type = tagging_type == "positive" ? "negative" : "positive";
  
  if (!tag_control) {
    parameters.attach_tagging_information_event = true;
    add_tag_control(taggable_id, tag_name);
  } else if (tag_control.hasClassName(other_tagging_type)) {
    tag_control.removeClassName(other_tagging_type);
    tag_control.addClassName(tagging_type);
    tag_information.removeClassName(other_tagging_type);
    tag_information.addClassName(tagging_type);
  } else if (tag_control.hasClassName('classifier')) {
    tag_control.addClassName(tagging_type); 
    tag_information.addClassName(tagging_type); 
  }
  
  sendTagRequest(url, parameters);
}

function remove_tagging(taggable_id, tag_name) {
  if( tag_name.match(/^\s*$/) ) { return; }

  var tag_control = $$('#' + taggable_id + ' .tag_control').detect(function(element) {
    return element.down(".name").innerHTML == tag_name;
  });
  var tag_information = $(taggable_id).down(".information");
  var url = '/taggings/destroy';
  var parameters = {
    "tagging[feed_item_id]": taggable_id.match(/(\d+)$/)[1],
    "tagging[tag]": tag_name,
  };
  
  if (tag_control) {
    tag_control.removeClassName('positive');
    tag_control.removeClassName('negative');
    tag_information.removeClassName('positive');
    tag_information.removeClassName('negative');
    if(!tag_control.match('.classifier')) {
      tag_control.removeClassName('selected');
      tag_information.removeClassName('selected');
      remove_tag_control(taggable_id, tag_name); 
    }
  }

  sendTagRequest(url, parameters);  
}

function sendTagRequest(url, parameters) {
  new Ajax.Request(url, { parameters: $H(parameters).toQueryString(), method: 'post',
    onFailure: function(transport) {
      new ErrorMessage("Error contacting server.  You're changes have not been saved.");
    }
  });
}

function add_tag_control(taggable_id, tag) {
  if (tag == null || tag == '') return false;
  var tag_controls = $('tag_controls_' + taggable_id);
  // TODO: needs to know the tag id to load the information panel
  var tag_control = '<li class="stop positive tag_control" style="display: none;">' + 
    // TODO: sanitize
    '<span class="name">' + tag + '</span>' + 
  '</li> ';
  insert_in_order(tag_controls, "li", "span.name", tag_control, tag);

  tag_control = $$('#' + taggable_id + ' .tag_control').detect(function(element) {
    return element.down(".name").innerHTML == tag;
  });
  Effect.Appear(tag_control);
}

function remove_tag_control(taggable_id, tag) {
  if (tag == null || tag == '') return false;  
  var tag_control = $$('#' + taggable_id + ' .tag_control').detect(function(element) {
    return element.down(".name").innerHTML == tag;
  });
  Effect.Fade(tag_control, { afterFinish: function() { tag_control.remove(); } });
}
