// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var ItemBrowser = Class.create({
  initialize: function(name, container, options) {
    this.options = {
      controller: name,
      url: name,
      orders: {}
    };
    Object.extend(this.options, options || {});
    
    this.name = name;
    this.update_queue = [];
    this.loading = false;
    this.full = false;
    
    this.container = $(container);

    document.observe('keypress', this.keypress.bindAsEventListener(this));
    this.container.observe('scroll', this.updateItems.bind(this));
    
    this.initializeFilters();
  },

  initializeFilters: function() {
    this.filters = { order: this.defaultOrder(), direction: this.defaultDirection() };
    
    if(location.hash.gsub('#', '').blank() && Cookie.get(this.name + "_filters")) {
      this.setFilters(Cookie.get(this.name + "_filters").toQueryParams());
    } else {
      this.setFilters(location.hash.gsub('#', '').toQueryParams());
    }
  },
  
  defaultOrder: function() {
    return this.options.orders["default"];
  },
  
  defaultDirection: function(order) {
    order = order || this.defaultOrder();
    
    if(this.options.orders.desc.include(order)) {
      return "desc";
    } else {
      return "asc";
    }
  },
  
  orders: function() {
    return (this.options.orders.asc || []).concat(this.options.orders.desc || []);
  },
  
  setFull: function(full) {
    this.full = full;
  },
  
  numberOfItems: function() {
    return this.container.childElements().select(function(element) {
      return !element.match(".indicator") && !element.match(".empty");
    });
  },
    
  updateEmptyMessage: function() {
    if(this.full && this.numberOfItems().size() == 0) {
      this.container.insert('<div class="empty" style="display:none">No items matched your search criteria.</div>');
      var message = $$("#" + this.container.getAttribute("id") + " > .empty").first();

      var message_padding = parseInt(message.getStyle("padding-top")) + parseInt(message.getStyle("padding-bottom"));
      var footer_height = $('footer') ? $('footer').getHeight() : 0;
      var top = (this.container.getHeight() - message.getHeight() - message_padding) / 2;
      message.style.top = top + "px";
    
      var left = (this.container.getWidth() - message.getWidth()) / 2;
      message.style.left = left + "px";

      message.show();
    } else {
      var message = $$("#" + this.container.getAttribute("id") + " > .empty").first();
      if(message) {
        message.remove();
      }
    }
  },
  
  buildUpdateURL: function(parameters) {
    return '/' + this.options.url + '?' + $H(this.filters).merge($H(parameters)).toQueryString();
  },
  
  updateFromQueue: function() {
    if (this.update_queue.any()) {
      var next_action = this.update_queue.shift();
      next_action();
    }
  },
  
  updateItems: function() {
    if(this.full || this.loading) { return; }    
    var scroll_bottom = this.container.scrollHeight - this.container.scrollTop - this.container.getHeight();
    if(scroll_bottom <= 100) {
      this.loading = true;
      this.doUpdate({offset: this.numberOfItems().size()});
    }
  },
  
  doUpdate: function(options) {
    this.showLoadingIndicator();
    
    new Ajax.Request(this.buildUpdateURL(options || {}), { 
      method: 'get', requestHeaders: { Accept: 'application/json' },
      onComplete: function(response) {
        var data = response.responseJSON;
        if(data.full) {
          this.setFull(true);
        }
        data.items.each(function(item) {
          this.insertItem(item.id, item.content);
        }.bind(this));
        
        this.updateEmptyMessage();
        this.hideLoadingIndicator();
        this.loading = false;
        this.updateFromQueue();
      }.bind(this)
    });  
  },
  
  insertItem: function(item_id, content) {
    new Insertion.Bottom(this.container, content);
    if(this.name == "feed_items") {
      new Item($(item_id));
    }
  },
  
  clear: function() {
    this.container.update('');
    this.selectedItem = null;
  },
  
  reload: function() {
    if (this.loading) {
      var self = this;
      this.update_queue.push(function() {
        self.loading = true;
        self.showLoadingIndicator();
        self.clear();
        self.doUpdate();
      });
    } else {
      this.loading = true;
      this.showLoadingIndicator();
      this.clear();
      this.doUpdate();
    }
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
  
  toggleSetFilters: function(parameters, event) {
    if(event && event.metaKey) {
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
        Event.stop(event);
      }
    } else {
      this.setFilters(parameters);
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
  
  setFilters: function(parameters) {
    this.expandFolderParameters(parameters);
    this.filters.tag_ids = null;
    this.filters.feed_ids = null;
    this.addFilters(parameters);
  },
  
  clearFilters: function(parameters) {
    var clear_selected_filters = $("clear_selected_filters");  
    if(!clear_selected_filters.hasClassName("disabled")) {
      this.setFilters({text_filter: ""});
    }
  },
  
  addFilters: function(parameters) {
    this.expandFolderParameters(parameters);

    if(this.filters.tag_ids && parameters.tag_ids) {
      var tag_ids = this.filters.tag_ids.split(",");
      tag_ids.push(parameters.tag_ids.split(","));
      parameters.tag_ids = tag_ids.flatten().uniq().join(",");
    }
    if(this.filters.feed_ids && parameters.feed_ids) {
      var feed_ids = this.filters.feed_ids.split(",");
      feed_ids.push(parameters.feed_ids.split(","));
      parameters.feed_ids = feed_ids.flatten().uniq().join(",");
    }
    
    var new_parameters = $H(this.filters).merge($H(parameters));
    this.filters = new_parameters.toQueryString().toQueryParams();
    
    this.saveFilters();    
    this.styleFilters();
    this.reload();
  },
  
  styleFilters: function() {
    if($("mode_all")) {
  	  var modes = ["all", "unread", "trained"];
  		if(this.filters.mode) {
  			modes.without(this.filters.mode).each(function(mode) {
  			  $("mode_" + mode).removeClassName("selected")
  			});
			
  			$("mode_" + this.filters.mode).addClassName("selected");
  		} else {
  			modes.without("unread").each(function(mode) {
  			  $("mode_" + mode).removeClassName("selected")
  			});

  			$("mode_unread").addClassName("selected");
  		}
    }
    
    this.styleOrders();
    
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
      
      if(items.size() > 0 && selected == items.size()) {
        folder.removeClassName("some_selected");
        folder.addClassName("selected");
      } else if(selected > 0) {
        folder.removeClassName("selected");
        folder.addClassName("some_selected");
      } else {
        folder.removeClassName("selected");
        folder.removeClassName("some_selected");        
      }
    });
    
    var text_filter = $("text_filter");
    if(text_filter) {
      if(this.filters.text_filter) {
        text_filter.value = this.filters.text_filter;
        text_filter.fire("applesearch:setup");
      } else {
        text_filter.value = "";
        text_filter.fire("applesearch:blur");
      }
    }
    
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
  
  setOrder: function(order) {
    if(this.filters.order == order) {
      this.filters.direction = (this.filters.direction == "asc" ? "desc" : "asc");
    } else {
      this.filters.order = order;
      this.filters.direction = this.defaultDirection(order);
    }
    this.saveFilters();
    this.styleFilters();
    this.reload();
  },
  
  saveFilters: function() {
    // Remove empty values
    var filters_hash = $H(this.filters);
    filters_hash.each(function(key_value) {
      var key = key_value[0];
      var value = key_value[1];
      if(value == null || Object.isUndefined(value) || (typeof(value) == 'string' && value.blank())) {
        filters_hash.unset(key);
      }
    });
    this.filters = filters_hash.toQueryString().toQueryParams();
    
    location.hash = "#" + $H(this.filters).toQueryString();
    Cookie.set(this.name + "_filters", $H(this.filters).toQueryString(), 365);
  },
  
  styleOrders: function() {
		this.orders().each(function(order) {
		  var order_control = $("order_" + order);
		  if(order_control) {
		    order_control.removeClassName("asc");
		    order_control.removeClassName("desc");
		    order_control.removeClassName("selected");
		  }
		});

		if(this.filters.order) {
		  var order_control = $("order_" + this.filters.order);
		  if(order_control) {
		    order_control.addClassName(this.filters.direction);
		    order_control.addClassName("selected");
		  }
		} else if(this.defaultOrder()) {
		  var order_control = $("order_" + this.defaultOrder());
		  if(order_control) {
		    order_control.addClassName(this.defaultDirection());
		    order_control.addClassName("selected");
		  }
		}
  },
  
  showLoadingIndicator: function() {
    this.container.insert('<div class="indicator" style="display:none">Loading Items...</div>');
    var indicator = $$("#" + this.container.getAttribute("id") + " > .indicator").first();

    if(this.numberOfItems().size() == 0) {
      var indicator_padding = parseInt(indicator.getStyle("padding-top")) + parseInt(indicator.getStyle("padding-bottom"));
      var footer_height = $('footer') ? $('footer').getHeight() : 0;
      var top = (this.container.getHeight() - indicator.getHeight() - indicator_padding) / 2;
      indicator.style.top = top + "px";
    }

    var left = (this.container.getWidth() - indicator.getWidth()) / 2;
    indicator.style.left = left + "px";
    
    indicator.show();
  },
  
  hideLoadingIndicator: function() {
    var indicator = $$("#" + this.container.getAttribute("id") + " > .indicator").first();
    indicator.remove();
  },

  selectItem: function(item) {
    item = $(item);
    
    this.deselectItem(this.selectedItem);
    this.selectedItem = item;
    this.selectedItem.addClassName('selected');
    item._item.scrollTo();
  },
  
  deselectItem: function(item) {
    this.selectedItem = null;
    if(item) {
      $(item).removeClassName('selected');
      $(item).down(".feed_title").removeClassName('selected');
      $(item).down(".feed_information").removeClassName('selected');
      $(item)._item.hideTrainingControls();
    }
  },
  
  openItem: function(item) {
    item = $(item);
    
    this.closeAllItems();
    if(this.selectedItem != item) {
      this.selectItem(item);
    }
    item.addClassName("open");
    item._item.markRead();
    item._item.scrollTo();
    item._item.loadBody();
  },
  
  closeItem: function(item) {
    item = $(item);
    
    if(item) {
      item.removeClassName("open");
      item._item.hideTrainingControls();
    }
  },
  
  closeAllItems: function() {
    $$(".feed_item.open").invoke("removeClassName", "open");
  },
  
  toggleOpenCloseItem: function(item, event) {
    if(event && (Event.element(event).match(".stop") || Event.element(event).up('.stop'))) { return false; }
    if($(item).match(".open")) {
      this.closeItem(item);
    } else {
      this.openItem(item);
    }
  },
  
  toggleOpenCloseSelectedItem: function() {
    if(this.selectedItem) {
      this.toggleOpenCloseItem(this.selectedItem);
    }
  },
  
  toggleOpenCloseSelectedItemModerationPanel: function() {
    this.selectedItem._item.toggleTrainingControls();
  },
  
  toggleReadUnreadSelectedItem: function() {
    if(this.selectedItem) {
      this.selectedItem._item.toggleReadUnread();
    }
  },
  
  markAllItemsRead: function() {
    $$('.feed_item.unread').invoke('addClassName', 'read').invoke('removeClassName', 'unread');
    new Ajax.Request('/' + this.options.controller + '/mark_read', {method: 'put'});
  },

  selectNextItem: function() {
    var next_item;
    if(this.selectedItem) {
      next_item = $(this.selectedItem).nextSiblings().first();
    } else {
      next_item = this.container.descendants().first();
    }
    if(next_item && next_item.hasClassName("feed_item")) {
      this.selectItem(next_item);
    }
  },
  
  selectPreviousItem: function() {
    var previous_item;
    if(this.selectedItem) {
      previous_item = $(this.selectedItem).previousSiblings().first();  
    }
    if(previous_item && previous_item.hasClassName("feed_item")) {
      this.selectItem(previous_item);
    }
  },
  
  openNextItem: function() {
    var next_item;
    if(this.selectedItem) {
      next_item = $(this.selectedItem).nextSiblings().first();
    } else {
      next_item = this.container.descendants().first();
    }
    if(next_item && next_item.hasClassName("feed_item")) {
      this.toggleOpenCloseItem(next_item);
    }
  },
  
  openPreviousItem: function() {
    var previous_item;
    if(this.selectedItem) {
      previous_item = $(this.selectedItem).previousSiblings().first();  
    }
    if(previous_item && previous_item.hasClassName("feed_item")) {
      this.toggleOpenCloseItem(previous_item);
    }
  },

  update_feed_filters: function(element, value) {
    element.value = "";
    if(value.match("#add_new_feed")) {
      new Ajax.Request("/feeds", {parameters: 'feed[url]='+encodeURIComponent(value.getAttribute("url")), method:'post'});
    } else {
      value.removeClassName('selected');
      $('feed_filters').insertInOrder('li', '.name', value, $(value).down(".name").innerHTML.unescapeHTML());
    	new Draggable(value.getAttribute("id"), {constraint:'vertical', ghosting:true, revert:true, reverteffect:function(element, top_offset, left_offset) { new Effect.Move(element, { x: -left_offset, y: -top_offset, duration: 0 }); }, scroll:'sidebar'});
      itemBrowser.toggleSetFilters({feed_ids: $(value).getAttribute("id").gsub("feed_", "")});
    	new Ajax.Request(value.getAttribute("subscribe_url"), {method:'put'});
    }
  },

  update_tag_filters: function(element, value) {
    element.value = "";
    if(value.match("#add_new_tag")) {
      new Ajax.Request("/tags", {parameters: 'name='+encodeURIComponent(value.getAttribute("name")), method:'post'});
    } else {
      value.removeClassName('selected');
      $('tag_filters').insertInOrder('li', '.name', value, $(value).down(".name").innerHTML.unescapeHTML());
    	new Draggable(value.getAttribute("id"), {constraint:'vertical', ghosting:true, revert:true, reverteffect:function(element, top_offset, left_offset) { new Effect.Move(element, { x: -left_offset, y: -top_offset, duration: 0 }); }, scroll:'sidebar'});
      itemBrowser.toggleSetFilters({tag_ids: $(value).getAttribute("id").gsub("tag_", "")});
    	new Ajax.Request(value.getAttribute("subscribe_url"), {method:'put'});
    }
  },

  clear_auto_complete: function(element, list) {
    list.update('');
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
    } else if(character == "m") {
      this.toggleReadUnreadSelectedItem();
      Event.stop(e);
    } else if(character == "t") {
      this.toggleOpenCloseSelectedItemModerationPanel();
      Event.stop(e);
    }
  }
});
