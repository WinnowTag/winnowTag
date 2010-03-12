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

var SEE_ALL_TAGS_ID = "0";

var FeedItemsItemBrowser = Class.create(ItemBrowser, {
  initialize: function($super, name, container, options) {
    $super(name, container, options);
    
    document.observe('keypress', this.keypress.bindAsEventListener(this));
    
    if (!this.filters.tag_ids) {
      var tag = $$("li.tag:first").first();
      if (tag) {
        var tag_id = tag.getAttribute("id").replace("tag_", "");
        this.toggleSetFilters({tag_ids: tag_id});
      }
    }
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
    } else if(character == " ") {
      this.openNextUnreadItem();
      Event.stop(e);
    }
  },

  selectedItem: function() {
    return $$(".feed_item.selected").first();
  },

  nextUnreadItem: function() {
    if(this.selectedItem()) {
      return this.selectedItem().next(".feed_item:not(.read)");
    } else {
      return this.container.down(".feed_item:not(.read)");
    }
  },
  
  nextItem: function() {
    if(this.selectedItem()) {
      return this.selectedItem().next(".feed_item");
    } else {
      return this.container.down(".feed_item");
    }
  },
  
  previousUnreadItem: function() {
    if(this.selectedItem()) {
      return this.selectedItem().previous(".feed_item:not(.read)");  
    }
  },
  
  previousItem: function() {
    if(this.selectedItem()) {
      return this.selectedItem().previous(".feed_item");  
    }
  },
  
  openNextItem: function() {
    var item = this.nextItem();
    
    if (item) {
      item._item.toggleBody();
    }
  },

  openNextUnreadItem: function() {
    var item = this.nextUnreadItem();
    
    if (!item) {
      this.container.childElements().last()._item.scrollTo();
      var that = this;
      var fun = function() {
        if (that.loading) {
          window.setTimeout(fun);
        } else {
          item = that.nextUnreadItem();
          if (item) {
            item._item.toggleBody();
          }
        }
      };
      
      window.setTimeout(fun, 500);
    } else if(item && item.hasClassName("feed_item")) {
      item._item.toggleBody();
    }
  },
  
  openPreviousUnreadItem: function() {
    var item = this.previousUnreadItem();
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

  setFilters: function($super, parameters) {
    this.filters.tag_ids = null;
    this.filters.feed_ids = null;
    $super(parameters);
  },
  
  addFilters: function($super, parameters) {
    if (!parameters.tag_ids && this.filters.tag_ids == null){
      parameters.tag_ids = SEE_ALL_TAGS_ID;
    }
    
    if (parameters.feed_ids) {
      parameters.tag_ids = SEE_ALL_TAGS_ID;
      parameters.text_filter = "";
      
      var feedTitle = parameters.feed_title;
      delete parameters.feed_title;
      if (!feedTitle) feedTitle = "Unnamed Feed";
      
      if ($("selectedFeed")) {
        $("selectedFeed").show();
        $("filteredFeedTitle").update(feedTitle);
      }
    } else {
      if ($("selectedFeed")) $("selectedFeed").hide();
      parameters.feed_ids = null;
    }
    
    /* Reset the mode to "all" if we are switching to 'See all tags' */
    if (parameters.tag_ids == SEE_ALL_TAGS_ID) {
      parameters.mode = "all";
    }
    
    $super(parameters);
  },

  toggleSetFilters: function(parameters, event) {
    this.setFilters(parameters);
    this.showDemoTagInfo();
  },
  
  removeFilters: function(parameters) {
    var new_parameters = Object.clone(this.filters);
    
    if(parameters.tag_ids) {
      new_parameters.tag_ids = (new_parameters.tag_ids || "").split(",").reject(function(tag_id) {
        return parameters.tag_ids.split(",").include(tag_id);
      }).join(",");
    }
    this.setFilters(new_parameters);
  },

  styleFilters: function($super) {
    $super();
    
    var tag_ids = this.filters.tag_ids ? this.filters.tag_ids.split(",") : [];
    $$(".tags li.tag").each(function(element) {
      var tag_id = element.getAttribute("id").gsub("tag_", "");
      if(tag_ids.include(tag_id)) {
        element.addClassName("selected");
      } else {
        element.removeClassName("selected");
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
    
    if (this.filters.tag_ids == SEE_ALL_TAGS_ID) {
      if ($("mode_trained")) $("mode_trained").addClassName("disabled");
    } else {
      if ($("mode_trained")) $("mode_trained").removeClassName("disabled");
    }
    
    this.showDemoTagInfo();
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
    
    if (link) {
      link.observe("click", click_event);    
    } else {
      tag.observe("click", click_event);
    }
  },
  
  showDemoTagInfo: function() {
    var footer_tag_name = $("footer_tag_name");
    
    if (footer_tag_name && this.filters.tag_ids && $A(this.filters.tag_ids.split(",")).first()) {
      var tagElement = $("tag_" + $A(this.filters.tag_ids.split(",")).first());
      
      if (tagElement && tagElement.getAttribute("name")) {
        footer_tag_name.update(tagElement.getAttribute("name"));
        $("footer_tag_positive_count").update(tagElement.getAttribute("pos_count"));
        $("footer_tag_negative_count").update(tagElement.getAttribute("neg_count"));
        $("footer_tag_count").update(tagElement.getAttribute("item_count"));
        $("tag_detail_footer").setStyle({"visibility": "visible"});
      } else {
        $("tag_detail_footer").setStyle({"visibility": "hidden"});
      }
    }
  },
  
  bindClearFilterEvents: function() {
    var clear_selected_filters = $("clear_selected_filters");
    if(clear_selected_filters) {
      clear_selected_filters.observe("click", this.clearFilters.bind(this));
    }
  },
  
  bindNextPreviousEvents: function() {
    $$("#next_unread").invoke("observe", "click", this.openNextUnreadItem.bind(this));
    $$("#previous_unread").invoke("observe", "click", this.openPreviousUnreadItem.bind(this));
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
  
  bindTagContextMenus: function() {
    $$("li.tag div.context_menu_button").each(function(button) {
      button.observe("click", this.showTagContextMenu.bindAsEventListener(this, button));
    }.bind(this));
  },
  
  bindTagContextMenu: function(tag) {
    $$("#" + tag + " div.context_menu_button").each(function(button) {
      button.observe("click", this.showTagContextMenu.bindAsEventListener(this, button));
    }.bind(this));
  },
  
  showTagContextMenu: function(event, button) {
    new TagContextMenu(button, button.getAttribute("tag-id"));
    event.stop();
  },
  
  initializeFilters: function($super) {
    $super();
    this.bindTagFiltersEvents();
    this.bindClearFilterEvents();
    this.bindNextPreviousEvents();
    this.bindMarkAllReadEvents();
    this.bindTagContextMenus();
  }
});
