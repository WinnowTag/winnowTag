// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
function add_tagging(taggable_id, tag_name, tagging_type) {
  if(tag_name.match(/^\s*$/)) { return; }

  var tag_control = $$('#' + taggable_id + ' .tag_control').detect(function(element) {
    return element.down(".name").innerHTML.unescapeHTML() == tag_name;
  });
  var training_control = $$('#' + taggable_id + ' .moderation_panel .tag').detect(function(element) {
    return element.down(".tag_name").innerHTML.unescapeHTML() == tag_name;
  });
  var url = '/taggings/create';
  var parameters = {
    "tagging[feed_item_id]": taggable_id.match(/(\d+)$/)[1],
    "tagging[tag]": tag_name,
    "tagging[strength]": tagging_type == "positive" ? 1 : 0
  };
  
  var other_tagging_type = tagging_type == "positive" ? "negative" : "positive";
  
  if (tag_control) {
    tag_control.removeClassName(other_tagging_type);
    tag_control.addClassName(tagging_type);
  } else {
    add_tag_control(taggable_id, tag_name);
  }

  if(training_control) {
    training_control.removeClassName(other_tagging_type);
    training_control.addClassName(tagging_type);
  } else {
    // TODO: Add training control      
  }
  
  sendTagRequest(url, parameters);
}

function remove_tagging(taggable_id, tag_name) {
  if(tag_name.match(/^\s*$/)) { return; }

  var tag_control = $$('#' + taggable_id + ' .tag_control').detect(function(element) {
    return element.down(".name").innerHTML.unescapeHTML() == tag_name;
  });
  var training_control = $$('#' + taggable_id + ' .moderation_panel .tag').detect(function(element) {
    return element.down(".tag_name").innerHTML.unescapeHTML() == tag_name;
  });
  var url = '/taggings/destroy';
  var parameters = {
    "tagging[feed_item_id]": taggable_id.match(/(\d+)$/)[1],
    "tagging[tag]": tag_name,
  };
  
  if (tag_control) {
    tag_control.removeClassName('positive');
    tag_control.removeClassName('negative');
    if(!tag_control.match('.classifier')) {
      tag_control.remove()
    }
  }

  if(training_control) {
    training_control.removeClassName('positive');
    training_control.removeClassName('negative');
  }

  sendTagRequest(url, parameters);  
}

function sendTagRequest(url, parameters) {
  new Ajax.Request(url, { parameters: $H(parameters).toQueryString(), method: 'post',
    onFailure: function(transport) {
      Message.add('error', "Error contacting server.  You're changes have not been saved.");
    }
  });
}

function add_tag_control(taggable_id, tag) {
  if (tag == null || tag == '') return false;
  var tag_controls = $('tag_controls_' + taggable_id);
  // TODO: needs to know the tag id to load the information panel
  var tag_control = '<li class="positive tag_control">' + 
    // TODO: sanitize
    '<span class="name">' + tag + '</span>' + 
  '</li> ';
  insert_in_order(tag_controls, "li", "span.name", tag_control, tag);
}

// function find_tag(container, tagClass, nameClass) {
//   var tag_control = $$(container + ' .' + tagClass).detect(function(element) {
//     return element.down(nameClass).innerHTML.unescapeHTML() == tag_name;
//   }); 
// }