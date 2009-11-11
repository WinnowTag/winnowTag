// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivative works.
// Please visit http://www.peerworks.org/contact for further information.

// Manages the list of feed items shown on the Items page. Provides:
//   * toggling for switching among summary and detail view of each item
//   * marking items read/unread
//   * navigation using keyboard shortcuts
//   * filtering by tag or feed

var FeedItemsItemBrowser = Class.create(ItemBrowser, {
  initialize: function($super, name, container, options) {
    $super(name, container, options);
    document.observe('keypress', this.keypress.bindAsEventListener(this));
  },

  keypress: function(e){
    if($(e.target).match('input') || $(e.target).match('select') || $(e.target).match('textarea')) {
      return;
    }
  
    if (e.metaKey || e.shiftKey || e.altKey || e.ctrlKey) {
      return;
    }
  
    var code = e.keyCode || e.which;
    var character = String.fromCharCode(code).toLowerCase();
    if(character == "j") {
      this.openNextItem();
      Event.stop(e);
    } else if(character == "k") {
      this.openPreviousItem();
      Event.stop(e);
    } else if(character == "n") {
      this.selectNextItem();
      Event.stop(e);
    } else if(character == "p") {
      this.selectPreviousItem();
      Event.stop(e);
    } else if(character == "o") {
      this.toggleOpenCloseSelectedItem();
      Event.stop(e);
    } else if(character == "t") {
      this.toggleOpenCloseSelectedItemModerationPanel();
      Event.stop(e);
    } else if(character == "m") {
      this.toggleReadUnreadSelectedItem();
      Event.stop(e);
    }
  },

  selectedItem: function() {
    return $$(".feed_item.selected").first();
  },

  nextItem: function() {
    if(this.selectedItem()) {
      return this.selectedItem().nextSiblings().first();
    } else {
      return this.container.descendants().first();
    }
  },
  
  previousItem: function() {
    if(this.selectedItem()) {
      return this.selectedItem().previousSiblings().first();  
    }
  },

  openNextItem: function() {
    var item = this.nextItem();
    if(item && item.hasClassName("feed_item")) {
      item._item.toggleBody();
    }
  },
  
  openPreviousItem: function() {
    var item = this.previousItem();
    if(item && item.hasClassName("feed_item")) {
      item._item.toggleBody();
    }
  },
  
  selectNextItem: function() {
    var item = this.nextItem();
    if(item && item.hasClassName("feed_item")) {
      item._item.select();
    }
  },
  
  selectPreviousItem: function() {
    var item = this.previousItem();
    if(item && item.hasClassName("feed_item")) {
      item._item.select();
    }
  },
  
  toggleOpenCloseSelectedItem: function() {
    if(this.selectedItem()) {
      this.selectedItem()._item.toggleBody();
    }
  },
  
  toggleOpenCloseSelectedItemModerationPanel: function() {
    this.selectedItem()._item.toggleTrainingControls();
  },
  
  toggleReadUnreadSelectedItem: function() {
    if(this.selectedItem()) {
      this.selectedItem()._item.toggleReadUnread();
    }
  },
  
  closeAllItems: function() {
    $$(".feed_item.open").each(function(item) {
      item._item.hideBody();
    });
  },

  deselectAllItems: function() {
    $$(".feed_item.selected").each(function(item) {
      item._item.deselect();
    });
  },
  
  markAllItemsRead: function() {
    this.container.select('.feed_item').invoke('addClassName', 'read');
    new Ajax.Request('/' + this.options.controller + '/mark_read' + '?' + $H(this.filters).toQueryString(), {method: 'put'});
  },
  
  markAllItemsUnread: function() {
    this.container.select('.feed_item').invoke('removeClassName', 'read');

    this.loading = true;
    this.clear();
    this.showLoadingIndicator();

    new Ajax.Request('/' + this.options.controller + '/mark_unread', {
      parameters: this.filters, method: 'put',
      onSuccess: function() {
        this.hideLoadingIndicator();
        this.loading = false;
        this.reload();
      }.bind(this)
    });
  },

  insertItem: function($super, item_id, content) {
    $super(item_id, content);
    new Item(item_id);
  },
  
  updateFeedFilters: function(element, feed) {
    element.clear();
    if(feed.match("#add_new_feed")) {
      new Ajax.Request("/feeds", {
        parameters: 'feed[url]=' + encodeURIComponent(feed.getAttribute("url")),
        method: 'post',
        onComplete: function() {
          this.styleFilters();  
        }.bind(this)
      });
    } else {
      if(!$('feed_filters').down("#" + feed.getAttribute("id"))) {
        feed.removeClassName('selected');
        $('feed_filters').insertInOrder('.name@data-sort', feed, $(feed).down(".name").getAttribute("data-sort"));
        this.bindFeedFilterEvents(feed);
        this.styleFilters();
      }
      new Ajax.Request(feed.getAttribute("subscribe_url"), {method:'put'});
    }
  },
  
  updateTagFilters: function(input, tag) {
    input.clear();
    if(!$('tag_filters').down("#" + tag.getAttribute("id"))) {
      tag.removeClassName('selected');
      $('tag_filters').insertInOrder('.name@data-sort', tag, $(tag).down(".name").getAttribute("data-sort"));
      this.bindTagFilterEvents(tag);
      this.styleFilters();
    }
    new Ajax.Request(tag.getAttribute("subscribe_url"), {method:'put'});
  },
  
  expandFolderParameters: function(parameters) {
    if(parameters.folder_ids) {
      var tag_ids = parameters.tag_ids ? parameters.tag_ids.split(",") : [];
      var feed_ids = parameters.feed_ids ? parameters.feed_ids.split(",") : [];
    
      parameters.folder_ids.split(",").each(function(folder_id) {
        var folder = $("folder_" + folder_id);
        if(folder_id == "tags" || folder_id == "feeds") {
          folder = $(folder_id + "_section");
        }
        folder.select(".tags li").each(function(element) {
          tag_ids.push(element.getAttribute("id").gsub("tag_", ""));
        });
        folder.select(".feeds li").each(function(element) {
          feed_ids.push(element.getAttribute("id").gsub("feed_", ""));        
        });
      });
      
      parameters.folder_ids = null;
      parameters.tag_ids = tag_ids.join(",");
      parameters.feed_ids = feed_ids.join(",");
    }
  },

  setFilters: function($super, parameters) {
    this.expandFolderParameters(parameters);
    this.filters.tag_ids = null;
    this.filters.feed_ids = null;
    $super(parameters);
  },
  
  addFilters: function($super, parameters) {
    this.expandFolderParameters(parameters);

    if(this.filters.tag_ids && parameters.tag_ids) {
      var tag_ids = this.filters.tag_ids.split(",");
      tag_ids.push(parameters.tag_ids.split(","));
      parameters = $H(parameters).merge({
        tag_ids: tag_ids.flatten().uniq().join(",")
      });
    }
    if(this.filters.feed_ids && parameters.feed_ids) {
      var feed_ids = this.filters.feed_ids.split(",");
      feed_ids.push(parameters.feed_ids.split(","));
      parameters = $H(parameters).merge({
        feed_ids: feed_ids.flatten().uniq().join(",")
      });
    }
    
    $super(parameters);
  },

  toggleSetFilters: function(parameters, event) {
    if(parameters.folder_ids) {
      var empty = false;
      parameters.folder_ids.split(",").each(function(folder_id) {
        var folder = $("folder_" + folder_id);
        if(folder_id == "tags" || folder_id == "feeds") {
          folder = $(folder_id + "_section");
        }
        empty = folder.hasClassName("empty");
      });
      if(empty) { return false; }
    }
    
    if(event && this.multiSelectKey(event)) {
      this.expandFolderParameters(parameters);
      var selected = true;
      if(parameters.feed_ids) {
        parameters.feed_ids.split(",").each(function(feed_id) {
          selected = selected && $("feed_" + feed_id).hasClassName("selected");
        });
      }
      if(parameters.tag_ids) {
        parameters.tag_ids.split(",").each(function(tag_id) {
          selected = selected && $("tag_" + tag_id).hasClassName("selected");
        });
      }
      
      if(selected) {
        this.removeFilters(parameters);
      } else {
        this.addFilters(parameters);
      }
    } else {
      this.setFilters(parameters);
    }
  },

  multiSelectKey: function(event) {
    if(navigator.platform.indexOf("Mac") != -1) {
      return event.metaKey;
    } else {
      return event.ctrlKey;
    }
  },
  
  removeFilters: function(parameters) {
    this.expandFolderParameters(parameters);
    
    var new_parameters = Object.clone(this.filters);
    if(parameters.feed_ids) {
      new_parameters.feed_ids = (new_parameters.feed_ids || "").split(",").reject(function(feed_id) {
        return parameters.feed_ids.split(",").include(feed_id);
      }).join(",");
    }
    if(parameters.tag_ids) {
      new_parameters.tag_ids = (new_parameters.tag_ids || "").split(",").reject(function(tag_id) {
        return parameters.tag_ids.split(",").include(tag_id);
      }).join(",");
    }
    this.setFilters(new_parameters);
  },
  
  clearFilters: function(parameters) {
    var clear_selected_filters = $("clear_selected_filters");  
    if(!clear_selected_filters.hasClassName("disabled")) {
      this.setFilters({text_filter: ""});
    }
  },

  styleFilters: function($super) {
    $super();
    
    var feed_ids = this.filters.feed_ids ? this.filters.feed_ids.split(",") : [];
    $$(".feeds li").each(function(element) {
      var feed_id = element.getAttribute("id").gsub("feed_", "");
      if(feed_ids.include(feed_id)) {
        element.addClassName("selected");
      } else {
        element.removeClassName("selected");
      }
    });
    
    var tag_ids = this.filters.tag_ids ? this.filters.tag_ids.split(",") : [];
    $$(".tags li").each(function(element) {
      var tag_id = element.getAttribute("id").gsub("tag_", "");
      if(tag_ids.include(tag_id)) {
        element.addClassName("selected");
      } else {
        element.removeClassName("selected");
      }
    });
    
    $$(".folder, #tags_section, #feeds_section").each(function(folder) {
      var items = folder.select(".filter_list li");
      var selected = 0;
      items.each(function(item) {
        if(item.hasClassName("selected")) {
          selected += 1;
        }
      });
      
      if(items.size() == 0) {
        folder.removeClassName("some_selected");
        folder.removeClassName("selected");
        folder.addClassName("empty");
      } else if(selected == items.size()) {
        folder.removeClassName("empty");
        folder.removeClassName("some_selected");
        folder.addClassName("selected");
      } else if(selected > 0) {
        folder.removeClassName("empty");
        folder.removeClassName("selected");
        folder.addClassName("some_selected");
      } else {
        folder.removeClassName("empty");
        folder.removeClassName("some_selected");        
        folder.removeClassName("selected");
      }
    });
    
    var clear_selected_filters = $("clear_selected_filters");
    if(clear_selected_filters) {
      if(this.filters.tag_ids || this.filters.feed_ids || this.filters.text_filter) {
        clear_selected_filters.removeClassName("disabled");
      } else {
        clear_selected_filters.addClassName("disabled");
      }
    }
    
    var feed_with_selected_filters = $("feed_with_selected_filters");
    if(feed_with_selected_filters) {
      feed_with_selected_filters.href = feed_with_selected_filters.getAttribute("base_url") + '?' + $H(this.filters).toQueryString();
    }
  },
  
  bindTagFiltersEvents: function() {
    $$(".filter_list.tags li.tag").each(function(tag) {
      this.bindTagFilterEvents(tag);
    }.bind(this));
  },

  bindTagFilterEvents: function(tag) {
    var tag_id = tag.getAttribute('id').match(/\d+/).first();
    var link = tag.down(".name");
    var click_event = this.toggleSetFilters.bind(this, {tag_ids: tag_id});
    link.observe("click", click_event);

    this.makeDraggable(tag, link, click_event);
  },
  
  bindFeedFiltersEvents: function() {
    $$(".filter_list.feeds li.feed").each(function(feed) {
      this.bindFeedFilterEvents(feed);
    }.bind(this));
  },
  
  bindFeedFilterEvents: function(feed) {
    var feed_id = feed.getAttribute('id').match(/\d+/).first();
    var link = feed.down(".name");
    var click_event = this.toggleSetFilters.bind(this, {feed_ids: feed_id});
    link.observe("click", click_event);
    
    this.makeDraggable(feed, link, click_event);
  },
  
  makeDraggable: function(tag_or_feed, link, click_event) {
    Draggables.addObserver({
      onStart: function(eventName, draggable, event) {
        if(draggable.element == tag_or_feed) {
          if(!draggable.element.match(".selected")) {
            click_event();
          }
          link.stopObserving("click", click_event);
        }
      },
      onEnd: function(eventName, draggable, event) {
        if(draggable.element == tag_or_feed) {
          setTimeout(function() {
            link.observe("click", click_event);
          }, 1);
        }
      }
    });
    
    this.draggableFor(tag_or_feed);
  },
  
  draggableFor: function(tag_or_feed) {
    new Draggable(tag_or_feed, {
      ghosting: true, revert: true, scroll: 'sidebar',
      reverteffect: function(element, top_offset, left_offset) {
        new Effect.Move(element, { x: -left_offset, y: -top_offset, duration: 0 });
      },
      onStart: function(draggable, event) {
        var selected = draggable.element.up(".multidrag").select('.selected').without(draggable._clone);
        if (selected.length > 1) {
          var info = new Element('div', { 'class': 'multidragcount' });
          info.insert(selected.length);
          draggable.element.insert({top: info});
        }
      },
      onEnd: function(draggable, event) {
        var info = draggable.element.down('.multidragcount');
        if(info) { info.remove(); }
      }
    });
  },

  bindTextFilterEvents: function() {
    $("text_filter_form").observe("submit", function() {
      var value = $F('text_filter');
      if(value.length < 4) {
        Message.add('error', I18n.t("winnow.notifications.feed_items_search_too_short"));
      } else {
        this.addFilters({text_filter: value});
      }
    }.bind(this));
  },
  
  bindClearFilterEvents: function() {
    var clear_selected_filters = $("clear_selected_filters");
    if(clear_selected_filters) {
      clear_selected_filters.observe("click", this.clearFilters.bind(this));
    }
  },
  
  bindNextPreviousEvents: function() {
    var previous_control = $("footer").down("a .previous");
    if(previous_control) {
      previous_control.up("a").observe("click", this.openPreviousItem.bind(this));
    }

    var next_control = $("footer").down("a .next");
    if(next_control) {
      next_control.up("a").observe("click", this.openNextItem.bind(this));
    }
  },
  
  bindMarkAllReadEvents: function() {
    var mark_all_read_control = $("footer").down("a .read");
    if(mark_all_read_control) {
      mark_all_read_control.up("a").observe("click", this.markAllItemsRead.bind(this));
    }

    var mark_all_unread_control = $("footer").down("a .unread");
    if(mark_all_unread_control) {
      mark_all_unread_control.up("a").observe("click", this.markAllItemsUnread.bind(this));
    }
  },
  
  initializeFilters: function($super) {
    $super();
    this.bindTagFiltersEvents();
    this.bindFeedFiltersEvents();
    this.bindClearFilterEvents();
    this.bindNextPreviousEvents();
    this.bindMarkAllReadEvents();
  }
});
