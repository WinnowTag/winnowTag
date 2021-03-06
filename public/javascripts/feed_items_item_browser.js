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

  googleAnalytics: function(item_count) {
    _gap._trackEvent(this.options.url, this.filters.tag_ids, this.filters.text_filter, item_count);
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
    
    if (parameters.feed_ids && parameters.feed_title) {
      parameters.tag_ids = SEE_ALL_TAGS_ID;
      parameters.text_filter = "";
      
      var feedTitle = parameters.feed_title;
      delete parameters.feed_title;
      if (!feedTitle) feedTitle = "Unnamed Feed";
      
      if ($("selectedFeed")) {
        $("selectedFeed").show();
        $("filteredFeedTitle").update(feedTitle);
        $("tag_detail_updating").hide();
        $("no_tag_detail_updating").hide();
        $("search_detail_updating").hide();
      }
    } else {
      if ($("selectedFeed")) {
        $("selectedFeed").hide();
        $("no_tag_detail_updating").show();
        $("search_detail_updating").show();
      }
      parameters.feed_ids = null;
      parameters.feed_title = null;
    }

    if (parameters.tag_ids == SEE_ALL_TAGS_ID) {
          $(document.body).addClassName("see_all_tags")
    } else {
      $(document.body).removeClassName("see_all_tags")
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

    // Update information bar per value of search string
    var search_updating = $("search_updating");
    var no_search_updating = $("no_search_updating");
    var search_detail_updating = $("search_detail_updating");
    var updating_search_tag_name = $("updating_search_tag_name");
    var updating_search_tag_detail = $("updating_search_tag_detail");
    
    if(search_detail_updating) {
      if(this.filters.text_filter) {
        search_detail_updating.update(this.filters.text_filter);
        search_updating.show();
        if (updating_search_tag_name.textContent != "")
          updating_search_tag_detail.show();
        else
          updating_search_tag_detail.hide();
        no_search_updating.hide();
      } else {
        search_detail_updating.update("");
        search_updating.hide();
        no_search_updating.show();
      }
    }

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

    var trained_checkbox = $("trained_checkbox");
    if (this.filters.tag_ids == SEE_ALL_TAGS_ID) {
      if (trained_checkbox) {
          trained_checkbox.disabled = true;
          $("trained_checkbox_label").title = I18n.t("winnow.items.sidebar.trained_checkbox_disabled_tooltip");
      }

    } else {
      if (trained_checkbox && trained_checkbox.disabled) {
           // We don't want to set the tooltip unless the checkbox was disabled,
           // as this function does get called unnecessarily.
          trained_checkbox.disabled = false;
          $("trained_checkbox_label").title = I18n.t("winnow.items.sidebar.trained_checkbox_unchecked_tooltip");
      }
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
    var click_event = this.toggleSetFilters.bind(this, {tag_ids: tag_id, mode: 'all'});
    tag.observe("click", click_event);
  },

  showDemoTagInfo: function() {
    var updating_tag_name = $("updating_tag_name");
    var updating_search_tag_name = $("updating_search_tag_name");
    var updating_search_tag_detail = $("updating_search_tag_detail")
    
    if (updating_tag_name && this.filters.tag_ids && $A(this.filters.tag_ids.split(",")).first()) {
      var tagElement = $("tag_" + $A(this.filters.tag_ids.split(",")).first());
      
      if (tagElement && tagElement.getAttribute("name")) {
        updating_tag_name.update(tagElement.getAttribute("name"));
        updating_search_tag_name.update(tagElement.getAttribute("name"));
        updating_search_tag_detail.show();
        $("updating_tag_count").update(tagElement.getAttribute("item_count") - tagElement.getAttribute("pos_count") - tagElement.getAttribute("neg_count"));
        $("tag_detail_updating").show();
        $("no_tag_detail_updating").hide();
      } else {
        $("tag_detail_updating").hide();
        if (!($("selectedFeed") && $("selectedFeed").visible()))
          $("no_tag_detail_updating").show();
        updating_search_tag_name.update("");
        updating_search_tag_detail.hide();
      }
    }
  },
  
  bindClearFilterEvents: function() {
    var clear_selected_filters = $("clear_selected_filters");
    if(clear_selected_filters) {
      clear_selected_filters.observe("click", this.clearFilters.bind(this));
    }
  },

  bindModeFiltersEvents: function($super) {
    $super();

    var trained_checkbox = $("trained_checkbox");
    if (trained_checkbox) trained_checkbox.observe("click", function() {
      if (!trained_checkbox.disabled && (this.filters.mode != "trained")) {
        this.addFilters({mode: "trained"});
          $("no_showing_only_examples").hide();
          $("showing_only_examples").show();
      } else {
        this.addFilters({mode: "all"});
          $("no_showing_only_examples").show();
          $("showing_only_examples").hide();
      }
    }.bind(this));
  },

  styleModes: function($super) {
    $super();

    if(this.filters.mode) {
      var trained_checkbox = $("trained_checkbox");
      if (trained_checkbox) {
        if (trained_checkbox && this.filters.mode == "trained") {
          trained_checkbox.checked = true;
          Sidebar.instance.ensurePanelOpen();
          $("trained_checkbox_label").title = I18n.t("winnow.items.sidebar.trained_checkbox_checked_tooltip");
          $("no_showing_only_examples").hide();
          $("showing_only_examples").show();
        } else {
          if (trained_checkbox.checked) {
            new Effect.Highlight("trained_checkbox_label", { startcolor: '#FFFF00', endcolor: '#ffffff', restorecolor: '#ffffff' });
            trained_checkbox.checked = false;
            $("no_showing_only_examples").show();
            $("showing_only_examples").hide();
          }
          $("trained_checkbox_label").title = I18n.t("winnow.items.sidebar.trained_checkbox_unchecked_tooltip");
        }
      }
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
  },
  
    scrollSelectedTagIntoView: function() {
    var current_tag = 'tag_' + $A(this.filters.tag_ids.split(",")).first();
    if (current_tag != "0" && $(current_tag)) {
      var tag_container = $('tag_container');
      if (!tag_container) tag_container = $('sidebar'); // When not logged in
      new Effect.ScrollToInDiv(tag_container, $(current_tag), 12);
    }
  }
});
