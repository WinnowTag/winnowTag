// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var Item = Class.create({
  initialize: function(element) {
    this.element          = element;
    this.id               = this.element.getAttribute('id').match(/\d+/).first();
    this.closed           = this.element.down(".closed");
    this.status           = this.element.down(".status");
    this.tag_list         = this.element.down(".tag_list");
    this.train            = this.element.down(".train");
    this.moderation_panel = this.element.down(".moderation_panel");
    this.feed_information = this.element.down(".feed_information");
    this.body             = this.element.down(".body");
    // this.add_tag_field    = this.moderation_panel.down("input[type=text]");
    
    this.setupEventListeners();
    
    this.element._item = this;
  },
  
  setupEventListeners: function() {
    this.closed.observe("click", function(event) {
      itemBrowser.toggleOpenCloseItem(this.element, event);
    }.bind(this));

    this.status.observe("click", function() {
      this.toggleReadUnread();
    }.bind(this));

    this.status.observe("mouseover", function() {
      // # TODO: localization
      this.status.title = 'Click to mark as ' + (this.element.match(".read") ? 'unread' : 'read');
    }.bind(this));

    this.train.observe("click", function() {
      this.toggleTrainingControls();
    }.bind(this));
    
    this.tag_list.select("li").invoke("observe", "click", function() {
      this.toggleTrainingControls();
    }.bind(this));
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
  
  scrollTo: function() {
    new Effect.ScrollToInDiv(this.element.up(), this.element, { duration: 0.3 });
  },
  
  loadBody: function() {
    this.load(this.body);
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
    if(!this.isSelected()) {
      itemBrowser.closeItem(itemBrowser.selectedItem);
      itemBrowser.selectItem(this.element);
    }

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
    this.add_tag_field = this.moderation_panel.down("input[type=text]");

    var panel = this.element.down(".moderation_panel");
    var form = panel.down("form");
    var training_controls_panel = panel.down(".training_controls");
          
    training_controls_panel.select(".tag").each(function(tag) {
      this.initializeTrainingControl(tag);
    }.bind(this));

    var selected_tag = null;
    
    var updateTags = function(field, value, event) {
      selected_tag = null;
      
      training_controls_panel.select(".tag").each(function(tag) {
        tag.removeClassName("selected");
        tag.removeClassName("disabled");
        
        var tag_name = tag.down(".name").innerHTML.unescapeHTML();
        
        if(value.blank()) {
          // Don't do anything
        } else if(!tag_name.toLowerCase().startsWith(value.toLowerCase())) {
          tag.addClassName("disabled")
        } else if(!selected_tag) {
          selected_tag = tag_name;
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
      });
    };
    
    new Form.Element.EventObserver(this.add_tag_field, updateTags, 'keyup');

    form.observe("submit", function() {
      window.add_tagging(this.element.getAttribute("id"), selected_tag || this.add_tag_field.value, "positive");
      this.add_tag_field.value = "";
      updateTags(null, "");
    }.bind(this));
    
    this.add_tag_field.observe("keydown", function(event) {
      if(event.keyCode == Event.KEY_ESC) { this.hideTrainingControls(); }
    }.bind(this));
    
    this.add_tag_field.focus();
    
    (function() {
      this.scrollTo();
    }).bind(this).delay(0.3);
  },
  
  initializeTrainingControl: function(tag) {
    var taggable_id = this.element.getAttribute("id");
    var tag_name = tag.down(".name").innerHTML.unescapeHTML();
    tag.down(".positive").observe("click", function() {
      if(tag.hasClassName("positive")) { return; }
      window.add_tagging(taggable_id, tag_name, "positive");
      tag.removeClassName("negative");
      tag.addClassName("positive");
    });
    tag.down(".negative").observe("click", function() {
      if(tag.hasClassName("negative")) { return; }
      window.add_tagging(taggable_id, tag_name, "negative");
      tag.removeClassName("positive");
      tag.addClassName("negative");
    });
    tag.down(".remove").observe("click", function() {
      if(!tag.hasClassName("positive") && !tag.hasClassName("negative")) { return; }
      window.remove_tagging(taggable_id, tag_name);
      tag.removeClassName("negative");
      tag.removeClassName("positive");
    });
  },
  
  load: function(target, onComplete, forceLoad) {
    if(!forceLoad && !target.empty()) { return; }
    
    target.update("");
    target.addClassName("loading");
    new Ajax.Updater(target, target.getAttribute("url"), { method: 'get',
      onComplete: function() {
        target.removeClassName("loading");
        if(onComplete)        { onComplete();    }
        if(this.isSelected()) { this.scrollTo(); }
      }.bind(this)
    });
  }
});