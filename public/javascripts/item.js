// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var Item = Class.create({
  initialize: function(element) {
    this.element           = $(element);
    this.id                = this.element.getAttribute('id').match(/\d+/).first();
    this.closed            = this.element.down(".closed");
    this.status            = this.element.down(".status");
    this.feed_title        = this.element.down(".feed_title");
    this.train             = this.element.down(".train");
    this.tag_list          = this.element.down(".tag_list");
    this.moderation_panel  = this.element.down(".moderation_panel");
    this.feed_information  = this.element.down(".feed_information");
    this.body              = this.element.down(".body");
    // this.training_controls = this.moderation_panel.down(".training_controls");
    // this.add_tag_field     = this.moderation_panel.down("input[type=text]");
    // this.add_tag_selected  = null;
    
    this.setupEventListeners();
    
    this.element._item = this;
  },
  
  setupEventListeners: function() {
    this.closed.observe("click", function(event) {
      this.toggleBody(event);
    }.bind(this));

    this.status.observe("click", this.toggleReadUnread.bind(this));

    this.status.observe("mouseover", function() {
      // # TODO: localization
      this.status.title = 'Click to mark as ' + (this.element.match(".read") ? 'unread' : 'read');
    }.bind(this));

    this.feed_title.observe("click", this.toggleFeedInformation.bind(this));
    this.train.observe("click", this.toggleTrainingControls.bind(this));
    this.tag_list.select("li").invoke("observe", "click", this.toggleTrainingControls.bind(this));
  },
  
  isRead: function() {
    return this.element.hasClassName("read");
  },
  
  markRead: function() {
    this.element.addClassName('read');
    new Ajax.Request('/feed_items/' + this.id + '/mark_read', { method: 'put' });
  },
  
  markUnread: function() {
    this.element.removeClassName('read');    
    new Ajax.Request('/feed_items/' + this.id + '/mark_unread', { method: 'put' });
  },
  
  toggleReadUnread: function() {
   this.isRead() ? this.markUnread() : this.markRead();
  },
  
  isSelected: function() {
    return this.element.hasClassName("selected");
  },
  
  isOpen: function() {
    return this.element.hasClassName("open");
  },
  
  scrollTo: function() {
    new Effect.ScrollToInDiv(this.element.up(), this.element, { duration: 0.3 });
  },
  
  loadBody: function() {
    this.load(this.body);
  },

  toggleBody: function(event) {
    if(event && (Event.element(event).match(".stop") || Event.element(event).up('.stop'))) { return false; }
    
    if(this.isOpen()) {
      this.hideBody();
    } else {
      this.showBody();
    }
  },
  
  showBody: function() {
    itemBrowser.closeAllItems();
    if(!this.isSelected()) {
      this.select();
    }
    this.element.addClassName("open");
    this.markRead();
    this.scrollTo();
    this.loadBody();
  },
  
  hideBody: function() {
    this.element.removeClassName("open");
    this.hideFeedInformation();
    this.hideTrainingControls();
  },
  
  select: function() {
    itemBrowser.deselectAllItems();
    this.element.addClassName('selected');
    this.scrollTo();
  },

  deselect: function() {
    this.element.removeClassName('selected');
    this.hideFeedInformation();
    this.hideTrainingControls();
  },
  
  toggleFeedInformation: function() {
    if(this.feed_title.hasClassName("selected")) {
      this.hideFeedInformation();
    } else {
      this.showFeedInformation();
    }
  },
  
  showFeedInformation: function() {
    this.select();
    this.feed_title.addClassName('selected');
    this.feed_information.addClassName('selected');

    this.scrollTo();
    this.loadFeedInformation();
  },

  hideFeedInformation: function() {
    this.feed_title.removeClassName("selected");
    this.feed_information.removeClassName("selected");
  },
  
  loadFeedInformation: function() {
    this.load(this.feed_information);
  },
  
  toggleTrainingControls: function() {
    if(this.moderation_panel.hasClassName("selected")) {
      this.hideTrainingControls();
    } else {
      this.showTrainingControls();
    }
  },
  
  showTrainingControls: function() {
    this.select();

    this.tag_list.hide();

    this.train.addClassName("selected");
    this.moderation_panel.addClassName("selected");
    this.loadTrainingControls();
  },
  
  hideTrainingControls: function() {
    this.tag_list.show();

    this.train.removeClassName("selected");
    this.moderation_panel.removeClassName("selected");
    if(this.add_tag_field) {
      this.add_tag_field.blur();
    }
  },

  loadTrainingControls: function() {
    this.load(this.moderation_panel, this.initializeTrainingControls.bind(this), true);
  },
  
  initializeTrainingControls: function() {
    this.training_controls = this.moderation_panel.down(".training_controls");
    this.close             = this.moderation_panel.down(".close");
    this.add_tag_form      = this.moderation_panel.down("form");
    this.add_tag_field     = this.add_tag_form.down("input[type=text]");

    this.close.observe("click", this.toggleTrainingControls.bind(this));

    this.training_controls.select(".tag").each(function(tag) {
      this.initializeTrainingControl(tag);
    }.bind(this));
    
    new Form.Element.EventObserver(this.add_tag_field, this.addTagFieldChanged.bind(this), 'keyup');

    this.add_tag_form.observe("submit", function() {
      this.addTagging(this.add_tag_selected || this.add_tag_field.value, "positive");
      this.add_tag_field.value = "";
      this.addTagFieldChanged(this.add_tag_field, "");
    }.bind(this));
    
    this.add_tag_field.observe("keydown", function(event) {
      if(event.keyCode == Event.KEY_ESC) { this.hideTrainingControls(); }
    }.bind(this));
    
    this.add_tag_field.focus();
    
    (function() {
      this.scrollTo();
    }).bind(this).delay(0.3);
  },
  
  addTagFieldChanged: function(field, value, event) {
    this.add_tag_selected = null;
    this.training_controls.select(".tag").each(function(tag) {
      tag.removeClassName("selected");
      tag.removeClassName("disabled");
      
      var tag_name = tag.down(".name").innerHTML.unescapeHTML();
      
      if(value.blank()) {
        // Don't do anything
      } else if(!tag_name.toLowerCase().startsWith(value.toLowerCase())) {
        tag.addClassName("disabled")
      } else if(!this.add_tag_selected) {
        this.add_tag_selected = tag_name;
        tag.addClassName("selected");
        
        // http://www.webreference.com/programming/javascript/ncz/3.html
        // if(event.metaKey || event.altKey || event.ctrlKey || event.keyCode < 32 || 
        //   (event.keyCode >= 33 && event.keyCode <= 46) || (event.keyCode >= 112 && event.keyCode <= 123)) {
        //   console.log("nope");
        //   // Don't do anything
        // } else {
        //   field.value = tag_name;
        //   if(field.createTextRange) {
        //     var textSelection = field.createTextRange();
        //     textSelection.moveStart("character", 0);
        //     textSelection.moveEnd("character", value.length - field.value.length);
        //     textSelection.select();
        //   } else if (field.setSelectionRange) {
        //     field.setSelectionRange(value.length, field.value.length);
        //   }
        // }
      }
    }.bind(this));
  },
  
  initializeTrainingControl: function(tag) {
    tag.down(".name").observe("click", function() {
      var tag_name = tag.down(".name").innerHTML.unescapeHTML();
      if(tag.hasClassName("positive")) {
        this.addTagging(tag_name, "negative");
        tag.removeClassName("positive");
        tag.addClassName("negative");
      } else if(tag.hasClassName("negative")) {
        this.removeTagging(tag_name);
        tag.removeClassName("negative");
      } else {
        this.addTagging(tag_name, "positive");
        tag.addClassName("positive");
      }
    }.bind(this));
  },
  
  addTagging: function(tag_name, tagging_type) {
    if(tag_name.match(/^\s*$/)) { return; }

    var other_tagging_type = tagging_type == "positive" ? "negative" : "positive";

    var tag_control = this.findTagElement(this.tag_list, ".tag_control", tag_name);
    if(tag_control) {
      tag_control.removeClassName(other_tagging_type);
      tag_control.addClassName(tagging_type);
    } else {
      this.addTagControl(tag_name, tagging_type);
    }
    
    var training_control = this.findTagElement(this.training_controls, ".tag", tag_name);
    if(training_control) {
      training_control.removeClassName(other_tagging_type);
      training_control.addClassName(tagging_type);
    } else {
      this.addTrainingControl(tag_name);
    }
      
    new Ajax.Request('/taggings/create', { method: 'post', requestHeaders: { Accept: 'application/json' },
      parameters: {
        "tagging[feed_item_id]": this.id,
        "tagging[tag]": tag_name,
        "tagging[strength]": tagging_type == "positive" ? 1 : 0
      },
      onSuccess: function(response) {
        var data = response.responseJSON;
        
        // Add the tag's id as a class to newly created controls so they get properly updated if 
        // the user renames or deletes them before reloading the page
        var tag_control = this.findTagElement(this.tag_list, ".tag_control", tag_name);
        tag_control.addClassName(data.id);
        var training_control = this.findTagElement(this.training_controls, ".tag", tag_name);
        training_control.addClassName(data.id);
        
        // TODO: Move this to itembrowser.js
        // Add/Update the filter for this tag
        if(!$('tag_filters').down("#" + data.id)) {
          $('tag_filters').insertInOrder("li", ".name", data.filterHtml, tag_name);
          itembrowser.bindTagFilterEvents($('tag_filters').down("#" + data.id));
          itemBrowser.styleFilters();
        } else {
          $$(".filter_list ." + data.id).each(function(element) {
            element.title = data.tooltip;
          });
        }
        
        // TODO: Moved this to classifier.js
        // Update the classification button's status
        var classification_button = $('classification_button');
        if (classification_button) {
          classification_button.disabled = false;
          $("progress_title").update(data.classifierProgress);
        }
      }.bind(this)
    });
    Classification.instance.enableClassification();
  },
  
  removeTagging: function(tag_name) {
    if(tag_name.match(/^\s*$/)) { return; }

    var tag_control = this.findTagElement(this.tag_list, ".tag_control", tag_name);
    if (tag_control) {
      tag_control.removeClassName('positive');
      tag_control.removeClassName('negative');
      if(!tag_control.match('.classifier')) {
        tag_control.remove()
      }
    }

    var training_control = this.findTagElement(this.training_controls, ".tag", tag_name);
    if(training_control) {
      training_control.removeClassName('positive');
      training_control.removeClassName('negative');
    }

    new Ajax.Request('/taggings/destroy', { method: 'post', requestHeaders: { Accept: 'application/json' },
      parameters: {
        "tagging[feed_item_id]": this.id,
        "tagging[tag]": tag_name
      },
      onSuccess: function(response) {
        var data = response.responseJSON;

        if(data.prompt_to_delete_tag) {
          new ConfirmationMessage(data.prompt_to_delete_tag_message, function() {
            new Ajax.Request(data.prompt_to_delete_tag_url, {method: 'delete'});
          });
        }

        // Update the filter for this tag
        $$(".filter_list ." + data.id).each(function(element) {
          element.title = data.tooltip;
        });
        
        // TODO: Moved this to classifier.js
        // Update the classification button's status
        var classification_button = $('classification_button');
        if (classification_button) {
          classification_button.disabled = false;
          $("progress_title").update(data.classifierProgress);
        }
      }
    });
    Classification.instance.enableClassification();
  },
  
  findTagElement: function(container, elementSelector, tag_name) {
    var tag = container.select(elementSelector).detect(function(element) {
      return element.down(".name").innerHTML.unescapeHTML() == tag_name;
    });
    return tag;
  },

  addTagControl: function(tag_name, tagging_type) {
    var tag_control = '<li class="tag_control stop ' + tagging_type + '">' + 
      '<span class="name">' + tag_name.escapeHTML() + '</span>' + 
    '</li> ';
    this.tag_list.insertInOrder("li", ".name", tag_control, tag_name);
  },

  addTrainingControl: function(tag_name) {
    var training_control = '<div class="tag positive" style="display:none">' + 
      '<a href="#" onclick="return false;" class="name">' + tag_name.escapeHTML() + '</a>' + 
    '</div> ';
    this.training_controls.insertInOrder("div", ".name", training_control, tag_name);
  
    var training_control = this.findTagElement(this.training_controls, ".tag", tag_name);
    this.initializeTrainingControl(training_control);
    training_control.appear();
  },
  
  load: function(target, onComplete, forceLoad) {
    target.load(function() {
      if(onComplete)        { onComplete();    }
      if(this.isSelected()) { this.scrollTo(); }
    }.bind(this), forceLoad);
  }
});