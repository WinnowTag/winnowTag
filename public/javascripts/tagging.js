// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
function add_tagging(taggable_id, tag_name, tagging_type) {
  if( tag_name.match(/^\s*$/) ) { return; }

  var match = tag_name.match(/^Create Tag: '(.+)'$/);
  if(match) { tag_name = match[1]; }

  var tag_control = $("tag_control_for_" + tag_name + "_on_" + taggable_id);
  var tag_info = $("tag_info_for_" + tag_name + "_on_" + taggable_id);
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
    tag_info.removeClassName(other_tagging_type);
    tag_info.addClassName(tagging_type);
  } else if (tag_control.hasClassName('classifier')) {
    tag_control.addClassName(tagging_type); 
    tag_info.addClassName(tagging_type); 
  }
  
  sendTagRequest(url, parameters);
}

function remove_tagging(taggable_id, tag_name) {
  if( tag_name.match(/^\s*$/) ) { return; }

  var tag_control = $("tag_control_for_" + tag_name + "_on_" + taggable_id);
  var tag_info = $("tag_info_for_" + tag_name + "_on_" + taggable_id);
  var url = '/taggings/destroy';
  var parameters = {
    "tagging[feed_item_id]": taggable_id.match(/(\d+)$/)[1],
    "tagging[tag]": tag_name,
  }
  
  if (tag_control) {
    tag_control.removeClassName('positive');
    tag_control.removeClassName('negative');
    tag_info.removeClassName('positive');
    tag_info.removeClassName('negative');
    if(!tag_control.match('.classifier')) {
      tag_control.removeClassName('selected');
      tag_info.removeClassName('selected');
      remove_tag_control(taggable_id, tag_name); 
    }
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
  var tag_info_id = 'tag_info_for_' + tag + '_on_' + taggable_id;
  var tag_control = '<li id="' + tag_control_id + '" class="stop tag_control positive" style="display: none;">' + 
    // TODO: sanitize
    '<span class="name" onclick="itemBrowser.selectTaggingInformation(this, \'' + escape_javascript(tag_info_id) + '\');">' + tag + '</span>' + 
  '</li> ';
  insert_in_order(tag_controls, "li", "span.name", tag_control, tag);
  Effect.Appear(tag_control_id);
}

function remove_tag_control(taggable_id, tag) {
  if (tag == null || tag == '') return false;  
  var tag_control_id = 'tag_control_for_' + tag + '_on_' + taggable_id;
  var tag_info_id = 'tag_info_for_' + tag + '_on_' + taggable_id;
  Element.remove(tag_info_id);
  Effect.Fade(tag_control_id, { afterFinish: function() { Element.remove(tag_control_id); } });
}

var tag_information_timeouts = {};
function show_tag_information(control) {
  clearTimeout(tag_information_timeouts[$(control).up('li').getAttribute("id")]);
  $(control).up('li').addClassName('info');
}

function hide_tag_information(control) {
  tag_information_timeouts[$(control).up('li').getAttribute("id")] = setTimeout(function() {
    $(control).up('li').removeClassName('info');
  }, 1);
}