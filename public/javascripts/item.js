// General info: http://doc.winnowtag.org/open-source
// Source code repository: http://github.com/winnowtag
// Questions and feedback: contact@winnowtag.org
//
// Copyright (c) 2007-2011 The Kaphan Foundation
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


// Represents a feed item shown on the items page. Provides:
//   * toggling for hiding/showing the moderation panel used to train tags
//   * training tags on the feed item
//   * marking items read/unread
var Item = Class.create({
  initialize: function(element) {
    this.element           = $(element);
    this.id                = this.element.getAttribute('id').match(/\d+/).first();
    this.closed            = this.element.down(".closed");
    this.status            = this.element.down(".status");
    this.feed_title        = this.element.down("a.feed_title");
    this.moderation_panel  = this.element.down(".moderation_panel");
    this.feed_information  = this.element.down(".feed_information");
    this.body              = this.element.down(".body");
    this.isDemo            = $("demo") != null;
    
    // Queues by tag name for tagging requests. See the TagQueue class
    // for more details.
    this.tagQueues = {};
    
    this.setupEventListeners();
    
    this.element._item = this;
  },
  
  setupEventListeners: function() {
    this.closed.observe("click", function(event) {
      this.toggleBody(event);
    }.bind(this));

    if (this.status) {
      this.status.observe("click", this.toggleReadUnread.bind(this));

      this.status.observe("mouseover", function() {
        if(this.element.match(".read")) {
          this.status.title = I18n.t("winnow.items.main.mark_unread");
        } else {
          this.status.title = I18n.t("winnow.items.main.mark_read");
        }
      }.bind(this));
    }
    
    if (this.feed_title) this.feed_title.observe("click", this.toggleFeedInformation.bind(this));
  },
  
  isRead: function() {
    return this.element.hasClassName("read");
  },
  
  markRead: function() {
    this.element.addClassName('read');
    if (!this.isDemo) {
      new Ajax.Request('/feed_items/' + this.id + '/mark_read', { method: 'put' });
    }
  },
  
  markUnread: function() {
    this.element.removeClassName('read');    
    if (!this.isDemo) {
      new Ajax.Request('/feed_items/' + this.id + '/mark_unread', { method: 'put' });      
    }
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
      this.hideTrainingControls();
    } else {
      this.showBody();
      if (sidebar && sidebar.isEditing && sidebar.isEditing()) {
        this.showTrainingControls();
      }
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
      if (this.isOpen() && sidebar && sidebar.isEditing && sidebar.isEditing()) {
        this.showTrainingControls();
      }
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
    if (this.feed_title) this.feed_title.removeClassName("selected");
    if (this.feed_information) this.feed_information.removeClassName("selected");
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
    if (!this.moderation_panel.hasClassName("selected")) {
      this.select();
      this.moderation_panel.addClassName("selected");
      this.loadTrainingControls();
    }
  },
  
  hideTrainingControls: function() {
    if (this.moderation_panel) this.moderation_panel.removeClassName("selected");
    if(this.add_tag_field) {
      this.add_tag_field.blur();
    }
  },

  loadTrainingControls: function() {
    this.load(this.moderation_panel, this.initializeTrainingControls.bind(this), true);
  },
  
  initializeTrainingControls: function() {
    this.training_controls = this.moderation_panel.down(".training_controls");

    this.training_controls.select(".tag").each(function(tag) {
      this.initializeTrainingControl(tag);
    }.bind(this));
    
    (function() {
      this.scrollTo();
    }).bind(this).delay(0.3);
  },
  
  initializeTrainingControl: function(tag) {
    tag.down(".name").observe("click", this.clickTag.bind(this, tag));
  },
  
  // Handles a click on a tag name when training feed items. Creates a
  // handler function that determines training type and calls the
  // appropriate method to add/remove a tagging. Adds this handler
  // function to a queue so it will be processed in order. See the TagQueue
  // class for more details.
  clickTag: function(tag) {
    var tag_name = tag.down(".name").innerHTML.unescapeHTML();
    
    var handleTag = function() {
      var clickedTagID = tag.getAttribute("id").gsub("tag_", "");
      var currentTagInSidebarID = $A(itemBrowser.filters.tag_ids.split(",")).first();
      var clickedTagIsCurrentTagInSidebar = clickedTagID == currentTagInSidebarID;

      if(tag.hasClassName("positive")) {
        this.addTagging(tag_name, "negative");
        tag.removeClassName("positive"); if (clickedTagIsCurrentTagInSidebar) itemBrowser.selectedItem().removeClassName("positive");
        tag.addClassName("negative"); if (clickedTagIsCurrentTagInSidebar) itemBrowser.selectedItem().addClassName("negative");
        tag.title = I18n.t('winnow.items.main.moderation_panel_negative_tag_tooltip', {tag_name: tag_name});
      } else if(tag.hasClassName("negative")) {
        this.removeTagging(tag_name);
        tag.removeClassName("negative"); if (clickedTagIsCurrentTagInSidebar) itemBrowser.selectedItem().removeClassName("negative");

        var tagStrength = tag.getAttribute("strength");
        if (tagStrength) {
          tag.title = I18n.t('winnow.items.main.moderation_panel_classifier_tag_tooltip', {strength:tagStrength, tag_name:tag_name});
        } else {
          tag.title = I18n.t('winnow.items.main.moderation_panel_no_tag_tooltip', {tag_name: tag_name});
        }
      } else {
        this.addTagging(tag_name, "positive");
        tag.addClassName("positive"); if (clickedTagIsCurrentTagInSidebar) itemBrowser.selectedItem().addClassName("positive");
        tag.title = I18n.t('winnow.items.main.moderation_panel_positive_tag_tooltip', {tag_name: tag_name});
      }
    }.bind(this);
    
    var tagQueue = this.tagQueueFor(tag_name);
    tagQueue.process(handleTag);
  },
  
  // Returns a new or existing TagQueue for the given tag name.
  tagQueueFor: function(tagName) {
    if (!this.tagQueues[tagName]) {
      this.tagQueues[tagName] = new TagQueue();
    }
    return this.tagQueues[tagName];
  },
  
  addTagging: function(tag_name, tagging_type) {
    if(tag_name.match(/^\s*$/)) { return; }

    var other_tagging_type = tagging_type == "positive" ? "negative" : "positive";

    new Ajax.Request('/taggings', { method: 'post', requestHeaders: { Accept: 'application/json' },
      parameters: {
        "tagging[feed_item_id]": this.id,
        "tagging[tag]": tag_name,
        "tagging[strength]": tagging_type == "positive" ? 1 : 0
      },
      onComplete: function() {
        this.tagQueueFor(tag_name).actionCompleted();
      }.bind(this),
      onSuccess: function(response) {
        var data = response.responseJSON;
        if(data.error) {
          Message.add("error", data.error);
        } else {
          // Change the tags shown in the moderation panel.
          var training_control = this.findTagElement(this.training_controls, ".tag", tag_name);
          if(training_control) {
            training_control.removeClassName(other_tagging_type);
            training_control.addClassName(tagging_type);
          } else {
            this.addTrainingControl(tag_name, data.sort_name);
          }
      
          // Add the tag's id as a class to newly created controls so they get properly updated if 
          // the user renames or deletes them before reloading the page
          var training_control = this.findTagElement(this.training_controls, ".tag", tag_name);
          training_control.addClassName(data.id);
        
          // TODO: Move this to itembrowser.js
          // Add/Update the filter for this tag
          if(!$('tag_filters').down("#" + data.id)) {
            $('tag_filters').insertInOrder(".name@data-sort", data.filterHtml, data.sort_name);
            itemBrowser.bindTagFilterEvents($('tag_filters').down("#" + data.id));
            itemBrowser.styleFilters();
          }
        
          // TODO: Moved this to classifier.js
          // Update the classification button's status
          var classification_button = $('classification_button');
          if (classification_button) {
            classification_button.disabled = false;
            classification_button.title = I18n.t('winnow.items.footer.start_classifier_tooltip')
            $("progress_title").update(data.classifierProgress);
          }
        }
      }.bind(this)
    });
    Classification.instance.enableClassification();
  },
  
  removeTagging: function(tag_name) {
    if(tag_name.match(/^\s*$/)) { return; }
    
    // Change the tags shown in the moderation panel.
    var training_control = this.findTagElement(this.training_controls, ".tag", tag_name);
    if(training_control) {
      training_control.removeClassName('positive');
      training_control.removeClassName('negative');
    }

    new Ajax.Request('/taggings', { method: 'delete', requestHeaders: { Accept: 'application/json' },
      parameters: {
        "tagging[feed_item_id]": this.id,
        "tagging[tag]": tag_name
      },
      onComplete: function() {
        this.tagQueueFor(tag_name).actionCompleted();
      }.bind(this),
      onSuccess: function(response) {
        var data = response.responseJSON;

        if(data.prompt_to_delete_tag) {
          new ConfirmationMessage(data.prompt_to_delete_tag_message, function() {
            new Ajax.Request(data.prompt_to_delete_tag_url, {method: 'delete'});
          });
        }

        // TODO: Moved this to classifier.js
        // Update the classification button's status
        var classification_button = $('classification_button');
        if (classification_button) {
          classification_button.disabled = false;
          classification_button.title = I18n.t('winnow.items.footer.start_classifier_tooltip')
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

  addTrainingControl: function(tag_name, sort_name) {
    var training_control = '<div class="tag">' + 
      '<a href="#" onclick="return false;" class="name" data-sort="' + sort_name.escapeHTML() + '">' + tag_name.escapeHTML() + '</a>' + 
    '</div> ';
    this.training_controls.insertInOrder(".name@data-sort", training_control, sort_name);
  
    var training_control = this.findTagElement(this.training_controls, ".tag", tag_name);
    this.initializeTrainingControl(training_control);
    training_control.highlight();
  },
  
  load: function(target, onComplete, forceLoad) {
    if (target) {
      target.load(function() {
        if(onComplete)        { onComplete();    }
        if(this.isSelected()) { this.scrollTo(); }
      }.bind(this), forceLoad);
    }
  }
});


// A queue for requests to tag a feed item.
//
// When training tags on a feed item, a user can click a tag several times
// in quick succession to change the training of the tag. For each click,
// a request is sent to Winnow. We want to process these requests in the
// order that they're made so that we ultimately honor the final click on
// the tag. This class facilitates that. Without queueing the requests,
// they could arrive out of order, causing the tag to be trained differently
// than the user intended.
var TagQueue = Class.create({
  initialize: function() {
    this.actions = [];
    this.isProcessing = false;
  },
  
  process: function(action) {
    if (this.isProcessing) {
      this.actions.push(action);
    } else {
      this.isProcessing = true;
      action();
    }
  },
  
  actionCompleted: function() {
    if (this.actions.any()) {
      var nextAction = this.actions.shift();
      nextAction();
    } else {
      this.isProcessing = false;
    }
  }
});

Ajax.Responders.register({
  onException: function(r, e) {
    throw e;
  }
});