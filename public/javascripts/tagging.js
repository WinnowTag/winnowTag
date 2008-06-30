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
      tag_control.removeClassName('hover');
      tag_info.removeClassName('hover');
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

// TODO: Update!
function add_tag_control(taggable_id, tag) {
  if (tag == null || tag == '') return false;
  var tag_controls = $('tag_controls_' + taggable_id);
  var tag_control_id = 'tag_control_for_' + tag + '_on_' + taggable_id;
  var tag_control = '<li id="' + tag_control_id + '" class="stop positive" style="display: none;">' + 
    // TODO: sanitize
    '<span class="name" onclick="show_tagging_information(this, \'' + escape_javascript(tag) + '\');">' + tag + '</span>' + 
    '<div class="information clearfix">' +
      '<div class="training">' + 
        // TODO: localize
        '<a class="positive" onclick="add_tagging(\'' + taggable_id + '\', \'' + escape_javascript(tag) + '\', \'positive\'); return false;" href="#">Make Positive</a> ' + 
        '<a class="negative" onclick="add_tagging(\'' + taggable_id + '\', \'' + escape_javascript(tag) + '\', \'negative\'); return false;" href="#">Make Negative</a> ' + 
        '<a class="remove" onclick="remove_tagging(\'' + taggable_id + '\', \'' + escape_javascript(tag) + '\'); return false;" href="#">Remove Training</a> ' + 
      '</div> ' +
      '<div class="automatic">' + 
        '<span class="status clearfix"></span>' +
      '</div> ' +
    '</div>' +
  '</li> ';
  insert_in_order(tag_controls, "li", "span.name", tag_control, tag);
  Effect.Appear(tag_control_id);
}

// TODO: Update!
function remove_tag_control(taggable_id, tag) {
  if (tag == null || tag == '') return false;  
  var tag_control_id = 'tag_control_for_' + tag + '_on_' + taggable_id;
  Effect.Fade(tag_control_id, { afterFinish: function() { Element.remove(tag_control_id) } });
}

function show_tagging_information(tag, information, tag_name) {
  tag = $(tag).up('li');
  information = $(information);

  if(tag.hasClassName("hover")) {
    tag.removeClassName("hover");
    information.removeClassName("hover");
  } else {
    $$('.tag_control').invoke("removeClassName", "hover");
    $$('.information').invoke("removeClassName", "hover");

    itemBrowser.selectItem(tag.up('.item'));
    tag.addClassName('hover');
    information.addClassName('hover');
    
    // new Effect.ScrollToInDiv(itemBrowser.scrollable, tag.down(".information"), {duration: 0.3, bottom_margin: 5});
  }
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