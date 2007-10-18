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

	var tag_control = $("tag_control_for_" + tag_name + "_on_" + taggable_id);
	var url = '/taggings/create';
	var parameters = {};
	parameters["tagging[feed_item_id]"] = taggable_id.match(/(\d+)$/)[1];
	parameters["tagging[tag]"] = tag_name;
	parameters["tagging[strength]"] = "1";
	

	if (!tag_control) {
		add_tag_control(taggable_id, tag_name);
	} else if (tag_control.match('.user_tagging.negative_tagging')) {
		tag_control.removeClassName('negative_tagging');
		tag_control.addClassName('tagged');
	} else if (tag_control.match('.tagged.user_tagging.bayes_classifier_tagging')) {
		tag_control.removeClassName('user_tagging');
		url = '/taggings/destroy';
	} else if (tag_control.match('.tagged.bayes_classifier_tagging')) {
		tag_control.addClassName('user_tagging'); 
	} else if (tag_control.match('.tagged.user_tagging') && allow_remove) {
		tag_control.removeClassName('user_tagging');
		tag_control.removeClassName('tagged');
		remove_tag_control(taggable_id, tag_name); 
		url = '/taggings/destroy';
	} else {
		console.log("Invalid tag control state: " + tag_control.classNames().toArray().join(' '));
	}

	sendTagRequest(url, parameters);
}

function remove_tag(taggable_id, tag_name) {
	var tag_control = $("tag_control_for_" + tag_name + "_on_" + taggable_id);
	var url = '/taggings/destroy';
	var parameters = {};
	parameters["tagging[feed_item_id]"] = taggable_id.match(/(\d+)$/)[1];
	parameters["tagging[tag]"] = tag_name;
	
	if (tag_control.match('.user_tagging.negative_tagging')) { 
		tag_control.removeClassName('user_tagging');
		tag_control.removeClassName('negative_tagging');
		tag_control.addClassName('tagged');
	} else if (tag_control.match('.tagged.bayes_classifier_tagging')) {
		tag_control.removeClassName('tagged');
		tag_control.addClassName('negative_tagging');
		tag_control.addClassName('user_tagging');
		parameters['tagging[strength]'] = "0";
		url = '/taggings/create';
	} else {
		console.log("Invalid tag control state: " + tag_control.classNames().toArray().join(' '));
	}

	sendTagRequest(url, parameters);
}


/** Sends the tag request to the server.
 */
function sendTagRequest(url, parameters) {
	new Ajax.Request(url, {parameters: $H(parameters).toQueryString(),
		method: 'post',
		onFailure: function(transport) {
			alert('The tag was not successfully removed.');
		},
		onException: function(transport, exception) {
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
	var unused_tag_controls = $('unused_tag_controls_' + taggable_id);
	
	var tag_control_id = 'tag_control_for_' + tag + '_on_' + taggable_id;
	var unused_tag_control_id = 'unused_tag_control_for_' + tag + '_on_' + taggable_id;
	
	var tag_control = '<li id="' + tag_control_id + '" class="tagged user_tagging" style="display: none;" onmouseover="show_tag_tooltip(this, \'' + escape_javascript(tag) + '\');">' + 
		'<span class="name">' + tag + '</span>' + 
		'<span class="add" onclick="add_tag(\'' + taggable_id + '\', \'' + escape_javascript(tag) + '\', true);" onmouseover="show_control_tooltip(this, this.parentNode, \'' + escape_javascript(tag) + '\');"></span>' + 
		'<span class="user"></span>' + 
		'<span class="remove" onclick="remove_tag(\'' + taggable_id + '\', \'' + escape_javascript(tag) + '\');" onmouseover="show_control_tooltip(this, this.ParentNode, \'' + escape_javascript(tag) + '\');"></span>' + 
	'</li>';

	var inserted = false;
	tag_controls.getElementsBySelector("li").each(function(element) {
		if(!inserted && element.getElementsBySelector("span.name").first().innerHTML.toLowerCase() > tag.toLowerCase()) {
			new Insertion.Before(element, tag_control + " ");
			inserted = true;
		}
	});
	
	if(!inserted) {
		new Insertion.Bottom(tag_controls, " " + tag_control);
	}
	
	Effect.Appear(tag_control_id);
	if($(unused_tag_control_id)) {
		Effect.Fade(unused_tag_control_id, { afterFinish: function() { Element.remove(unused_tag_control_id) } }); }
}

function escape_javascript(string) {
	return string.replace(/'/g, '\\\'');
}

function remove_tag_control(taggable_id, tag) {
	if (tag == null || tag == '') return false;
	var tag_controls = $('tag_controls_' + taggable_id);
	var unused_tag_controls = $('unused_tag_controls_' + taggable_id);
	
	var tag_control_id = 'tag_control_for_' + tag + '_on_' + taggable_id;
	var unused_tag_control_id = 'unused_tag_control_for_' + tag + '_on_' + taggable_id;
	
	var unused_tag_control = '<li id="' + unused_tag_control_id + '" class="cursor" style="display: none;" onclick="add_tag(\'' + taggable_id + '\', \'' + escape_javascript(tag) + '\');" onmouseover="show_tag_tooltip(this, \'' + escape_javascript(tag) + '\');">' + 
		'<span class="name">' + tag + '</span>' + 
	'</li>';

	var inserted = false;
	unused_tag_controls.getElementsBySelector("li").each(function(element) {
		if(!inserted && element.getElementsBySelector("span.name").first().innerHTML.toLowerCase() > tag.toLowerCase()) {
			new Insertion.Before(element, unused_tag_control + " ");
			inserted = true;
		}
	});
	
	if(!inserted) {
		new Insertion.Bottom(unused_tag_controls, " " + unused_tag_control);
	}
	
	Effect.Appear(unused_tag_control_id);
	Effect.Fade(tag_control_id, { afterFinish: function() { Element.remove(tag_control_id) } });
}

function show_control_tooltip(control, tag, tag_name) {
	var control_tooltip = "";
	
	if (tag.match('.user_tagging.negative_tagging')) {
		control_tooltip = "Click to remove this negative example of " + tag_name;
	} else if (tag.match('.user_tagging.tagged')) {
		control_tooltip = "Click to remove this positive example of " + tag_name;
	} else if (tag.match('.tagged.bayes_classifier_tagging')) {
		if(control.match(".add")) {
			control_tooltip = "Click if this is a very good example of " + tag_name;
		}	else if(control.match(".remove")) {
			control_tooltip = "Click if this is a bad example of " + tag_name;
		}
	}

	control.setAttribute("title", control_tooltip);
}

function show_tag_tooltip(tag, tag_name) {
	var tag_tooltip = "";
	
	if (tag.match('.user_tagging.negative_tagging')) {
		tag_tooltip = "Negative training example for Winnow";
	} else if (tag.match('.tagged.user_tagging')) {
		tag_tooltip = "Positive training example for Winnow";
	} else if (tag.match('.tagged.bayes_classifier_tagging')) {
		tag_tooltip = "Winnow figured this item fit your examples";
	} else {
		tag_tooltip = "Click if this is a very good example of " + tag_name;
	}
	//TODO: Published tags: "Published by <name of user>"
	
	tag.setAttribute("title", tag_tooltip);
}

Effect.ScrollToInDiv = Class.create();
Object.extend(Object.extend(Effect.ScrollToInDiv.prototype, Effect.Base.prototype), {
  initialize: function(container, element, position) {
		this.container = $(container);
    this.element = $(element);
		this.position = position;
    this.start(arguments[3] || {});
  },
  setup: function() {
    Position.prepare();
		var containerOffset = Position.cumulativeOffset(this.container);
    var offsets = Position.cumulativeOffset(this.element);
    if(this.options.offset) {
			offsets[1] += this.options.offset;
		}

   	this.scrollStart = this.container.scrollTop;
		if(this.position == "top") {
    	this.delta = offsets[1] - this.scrollStart - containerOffset[1];
		} else if(this.position == "bottom") {
			if(offsets[1] + this.element.getHeight() > containerOffset[1] + this.scrollStart + this.container.getHeight()) {
				if(this.element.getHeight() > this.container.getHeight()) {
		    	this.delta = offsets[1] - this.scrollStart - containerOffset[1];
				} else {
					this.delta = offsets[1] - this.scrollStart - containerOffset[1] + this.element.getHeight() - this.container.getHeight();
				}
			} else {
				this.delta = 0;
			}
		}
  },
  update: function(position) {
    Position.prepare();
    this.container.scrollTop = this.scrollStart + (position*this.delta);
  }
});


/* TODO: Move into itembrowser.js */
function checkNewTag(item_id) {
	var newTagField = $('new_tag_field_' + item_id);
	if (newTagField && newTagField.value != "") {		
	 	if (confirm('Do you want to add ' + newTagField.value + ' to this item?')) {
			// add_tag_control($('global_tag_list_for_' + item_id),
			// 				newTagField, 
			// 				item_id);			
			//TODO: Change to toggle_tag
		}
	}
}

function closeItem(item_id) {
		checkNewTag(item_id);	
}