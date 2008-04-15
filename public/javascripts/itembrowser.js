// Copyright (c) 2007 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please contact info@peerworks.org for further information.

var ItemBrowser = Class.create();
ItemBrowser.instance = null;
/** Provides the ItemBrowser functionality.
 *
 *  The Item Browser is a scrollable view over the entire list of items
 *  in the database.  Items are lazily loaded into the browser as the 
 *  users scrolls the view around.
 */
ItemBrowser.prototype = {
  /** Initialization function.
   *
   *  @param container The element or id of the container div.
   *         This is the div that lies within scrollable div.
   *         The container div holds the item elements
   *         The ItemBrowser will look for another element with the id
   *         container + '_scrollable' that will be used as the
   *         scrollable div.
   *
   *  @param options A hash of options.  Supported options are:
   *         - update_threshold: The minimum number of items that will be fetched in
   *                             an update for that update to occur.
   *
   */
  initialize: function(container, options) {
    ItemBrowser.instance = this;
    
    this.options = {
      update_threshold: 8,
      controller: container,
      url: container
    };
    Object.extend(this.options, options || {});
    
    document.observe('keypress', this.keypress.bindAsEventListener(this));
    
    this.update_queue = new Array();
    
    // counts of the number of pruned items
    this.pruned_items = 0;
    
    // Flag for loading item - so we don't load them more than once at a time.
    this.loading = false;    
    this.container = $(container);
    this.scrollable = $('content');

    this.initializeItemList();
    
    var self = this;
    Event.observe(this.scrollable, 'scroll', function() { self.scrollView(); });
    
    this.auto_completers = {};

    if(location.hash.gsub('#', '').blank() && Cookie.get(this.container.getAttribute("id") + "_filters")) {
      this.setFilters(Cookie.get(this.container.getAttribute("id") + "_filters").toQueryParams());
    } else {
      this.setFilters(location.hash.gsub('#', '').toQueryParams());
    }

    this.loadSidebar();    
  },
  
  /** Called to initialize the internal list of items from the items loaded into the container.
   *
   *  An items position within the list corresponds to it's position within the sort order of the item
   *  list in the database.
   *
   *  This method should be considered private. 
   */
  initializeItemList: function() {
    this.items = [];
    Object.extend(this.items, {
      insert: function(list_postion, item_id, item_position, item_element) {
        this.splice(list_postion, 0, {position: item_position, element: item_element});
        this[item_id] = true;
      }
    });
    
    this.container.select('.item').each(function(fi) {
      this.items.insert(this.items.length, fi.getAttribute('id'), fi.getAttribute('position'), fi);
    }.bind(this));
  },
  
  itemHeight: function() {
    if (this.items[0] && this.items[1]) {
      var height = Math.min(this.items[0].element.offsetHeight, this.items[1].element.offsetHeight);
      height += parseInt(this.items[0].element.getStyle("padding-bottom"));
      return height;
    } else {
      return 0;
    }
  },
  
  updateCount: function() {
    $(this.container.getAttribute("id") + '_count').update("About " + this.items.compact().length + " items");
  },
  
  /** Returns the number of items in the viewable area of the scrollable container */
  numberOfItemsInView: function() {
    return Math.round(this.scrollable.getHeight() / this.itemHeight());
  },
  
  /** Sets the total number of items.
   *
   *  total_items in the number of items in the item database that could be loaded into
   *  this view.
   */
  setTotalItems: function(total_items) {
    if (this.total_items != total_items) {
      this.total_items = total_items;
      this.updateInitialSpacer();
    }
    this.updateEmptyMessage();
  },
  
  /** Updates the initial spacer's height to cover the total number of items minus the number of 
   *  items already loaded.
   */
  updateInitialSpacer: function() {
    var height = (this.total_items - this.items.length) * this.itemHeight();
    var spacer = this.container.down(".item_spacer");
    
    if (!spacer) {
      new Insertion.Bottom(this.container, '<div class="item_spacer"></div>');
      spacer = this.container.down(".item_spacer");
    }
    
    spacer.setStyle({height: '' + height + 'px'});    
  },
  
  updateEmptyMessage: function() {
    var spacer = this.container.down(".empty");
    
    if (!spacer) {
      new Insertion.Bottom(this.container, '<div class="empty" style="display:none">No items matched your search criteria.</div>');
      spacer = this.container.down(".empty");
    }
    
    if(this.total_items == 0) {
      spacer.show();
    } else {
      spacer.hide();
    }
  },
  
  /** Responds to scrolling events on the scrollable.
   *
   *  When a scrolling event occurs a function will be registered with
   *  a 500ms delay to call the updateItems method. Subsequent scrolling
   *  events within 500ms will clear that function and register a new one.
   *  The reason for this is that the scroll event is dispatched constantly by 
   *  the browser as the viewport is scrolled, so the prevent multiple updates
   *  being requested we only issue an update when the user has stopped scrolling
   *  for at least 500ms.
   */
  scrollView: function() {
    if (this.item_loading_timeout) {      
      clearTimeout(this.item_loading_timeout);
    }
    
    var scrollTop = this.scrollable.scrollTop;
    // bail out of scrollTop is zero - this prevents prematurely 
    // getting items when the list is cleared.
    if (scrollTop == 0) {return;}
    var offset = Math.floor(scrollTop / this.itemHeight());
    
    this.item_loading_timeout = setTimeout(function() {
      if (this.loading) {
        var self = this;
        this.update_queue.push(function() {
          self.updateItems({offset: offset});
        });
      } else {
        this.updateItems({offset: offset});        
      }
    }.bind(this), 300);
  }, 
  
  /** Creates the update URL from a list of options. */
  buildUpdateURL: function(parameters) {
    return '/' + this.options.url + '?' + $H(location.hash.gsub('#', '').toQueryParams()).merge($H(parameters)).toQueryString();
  },
  
  updateFromQueue: function() {
    if (this.update_queue.any()) {
      var next_action = this.update_queue.shift();
      next_action();
    }
  },
  
  /** This function is responsible for determining which items to fetch
   *  from the server and invoking doUpdate with those parameters.
   * 
   *  updateItems accepts an offset parameter as one
   *  of the options.  This parameter is interpreted as the position of the
   *  top of the scroll viewport, it then attempts to gets item to cover the
   *  previous half page, the current page and the first half of the next page.
   */
  updateItems: function(options) {
    if(this.items.compact().length == this.total_items) { return; }
    if(this.loading)                                    { return; }
    this.loading = true;
    
    var update_options = Object.clone(options);
    
    var do_update = false;
    // This is the standard update method.
    //
    // Start half a page ahead and behind the current page and 
    // 'squeeze' in until we have a set of items to load.     
    if (update_options) {
      var items_in_view = this.numberOfItemsInView();
      // The raw_offset is the item half a page behind the current page
      var raw_offset = Math.floor(options.offset - (items_in_view / 2));
      // Keep the actual offset above 0
      var offset = Math.max(raw_offset, 0);
      // The number of items is twice the page size, adjust for < 0 raw offsets.
      var limit = (items_in_view * 2) + Math.min(raw_offset, 0);
      var last_item = offset + limit - 1;
    
      // "squeeze" in the end points to they don't overlap with any loaded items.
      while (this.items[offset] && offset < last_item) {offset++; limit--;}
      while (this.items[offset + limit - 1] && limit > 0) {limit--;}
      Object.extend(update_options, {offset: offset, limit: limit});
      
      if (limit >= this.options.update_threshold) {
        do_update = true;
      } else if (options.offset <= offset && offset <= options.offset + items_in_view) {
        // If it is below the limit, but within the current view, do the update
        do_update = true;
      }      
    }
        
    if (do_update) {
      this.showLoadingIndicator();
      this.doUpdate(update_options);
    } else {
      this.loading = false;
    }
  },
  
  // Issues the request to get new items. 
  doUpdate: function(options) {
    options = options || {};
    new Ajax.Request(this.buildUpdateURL(options), {evalScripts: true, method: 'get',
      onComplete: function() {
        this.updateCount();
        this.hideLoadingIndicator();
        this.loading = false;
        this.updateFromQueue();
      }.bind(this)
      // onFailure: function(request) {
      //   // we get a status code of 2147746065 when the request gets interrupted in FF3B4
      //   if(request.status == 2147746065) { return; }
      //   new ErrorMessage("Failure: " + request.status);
      // },
      // onException: function(request, exception) {
      //   if (!exceptionToIgnore(exception)) {
      //     new ErrorMessage("Exception: " + exception.toString());
      //   }
      // }
    });  
  },
  
  /** This is old and not used, but we might need something like so it is here for reference. */
  pruneExcessItems: function(options) {
    if (this.options.window_size < this.items.length) {
      var going_up = options && options.direction == 'up';
      var index_to_remove_from = 0;
      var items = this.items;
      var totalHeight = 0;
      var number_to_remove = this.items.length - this.options.window_size;
      
      // If the view is being scrolled up prune items from the bottom
      if (going_up) {
        items = items.reverse(false);
        index_to_remove_from = items.length - number_to_remove;
      }
      
      // This may look like it can be done in the one loop, however
      // removing an item seems to make the next request for the offsetHeight
      // very slow, I assume it must have to recalculate the height when the DOM
      // is changed.  It is much faster to loop through once and get the heights
      // of the elements to remove and then loop through again to remove the elements.
      // Then once this is done we adjust the position of the scroll view to 
      // compensate for the items that have been removed.
      for (var i = 0; i < number_to_remove; i++) {
        if (going_up) {
          this.pruned_items--;          
        } else {
          this.pruned_items++;
          totalHeight += items[i].element.offsetHeight;          
        }
      }
      for (var i = 0; i < number_to_remove; i++) {
        items[i].element.remove();
        this.items[items[i].element.getAttribute('id')] = false;
      }
      
      this.items.splice(index_to_remove_from, number_to_remove);
      this.container.scrollTop -= totalHeight;
    }
  },
  
  /** Inserts an item into the item container.
   *
   *  Items are inserted by using their position within the list of items to
   *  find how many items not yet loaded come before and after the new item.
   *  This empty space is filled with a spacer div whose height is equal to the
   *  number of items that would fit in the gap * the height of an item.
   *  This ensures that each item is positioned both in the items list and
   *  the item container that corresponds to their position in the list
   *  of items in the database, with empty space between items filled in by 
   *  a spacer div for each gap.
   * 
   */
  insertItem: function(item_id, position, content) {
    if (this.items[position] == null) {
      // find the item immediately before this one
      var previous_position = position - 1;
      while (previous_position >= 0 && this.items[previous_position] == null) {previous_position--;}
      // find the item immediate after this one
      var next_position = position + 1;
      while (next_position < this.items.length && this.items[next_position] == null) {next_position++;}
      if (next_position > this.items.length) {
        next_position = this.total_items;
      }
      
      var existing_spacer = null;
      
      if (this.items[previous_position]) {
        existing_spacer = this.items[previous_position].element.nextSiblings().first();
      } else {
        existing_spacer = this.container.immediateDescendants().first();
      }
      
      var first_spacer_height = (position - previous_position - 1) * this.itemHeight();
      var next_spacer_height = (next_position - position - 1) * this.itemHeight();
      var first_spacer_content = '';
      var next_spacer_content = '';

      if (first_spacer_height > 0) {
        first_spacer_content = '<div class="item_spacer" style="height: ' + first_spacer_height  + 'px;"></div>';        
      }
      
      if (next_spacer_height > 0) {
        next_spacer_content = '<div class="item_spacer" style="height: ' + next_spacer_height  + 'px;"></div>';        
      }
      
      // insert the new item, with a spacer on either side, after the previous item
      if (existing_spacer) {
        existing_spacer.replace(first_spacer_content + content + next_spacer_content);
      } else {
        new Insertion.Bottom(this.container, first_spacer_content + content + next_spacer_content);
      }
      this.items[position] = {element: $(item_id), position: $(item_id).getAttribute('position')};
      this.items[item_id] = true;
    }
  },
  
  clear: function() {
    this.container.update('');
    this.selectedItem = null;
    this.initializeItemList();
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
  
  loadSidebar: function() {
    var sidebar = $("sidebar");
    if(sidebar) {
      sidebar.addClassName("loading");

      new Ajax.Updater("sidebar", "/" + this.options.controller + "/sidebar", { method: 'get', parameters: location.hash.gsub('#', ''), evalScripts: true,
        onComplete: function() {
          sidebar.removeClassName("loading");
          AppleSearch.setup();
          ItemBrowser.instance.styleFilters();
        }
      });
    }
  },
  
  expandFolderParameters: function(parameters) {
    if(parameters.folder_ids) {
      var tag_ids = parameters.tag_ids ? parameters.tag_ids.split(",") : [];
      var feed_ids = parameters.feed_ids ? parameters.feed_ids.split(",") : [];
    
      parameters.folder_ids.split(",").each(function(folder_id) {
        var folder = $("folder_" + folder_id);
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
    
    var new_parameters = location.hash.gsub('#', '').toQueryParams();
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

    // Clear out any tag/feed ids
    var old_parameters = $H(location.hash.gsub('#', '').toQueryParams());
    old_parameters.unset("tag_ids");
    old_parameters.unset("feed_ids");
    if(old_parameters.keys().size() == 0) {
      location.hash = " ";
    } else {
      location.hash = "#" + old_parameters.toQueryString();
    }
    
    this.addFilters(parameters);
  },
  
  addFilters: function(parameters) {
    this.expandFolderParameters(parameters);

    // Update location.hash
    var old_parameters = location.hash.gsub('#', '').toQueryParams();
    if(old_parameters.tag_ids && parameters.tag_ids) {
      var tag_ids = old_parameters.tag_ids.split(",");
      tag_ids.push(parameters.tag_ids.split(","));
      parameters.tag_ids = tag_ids.flatten().uniq().join(",");
    }
    if(old_parameters.feed_ids && parameters.feed_ids) {
      var feed_ids = old_parameters.feed_ids.split(",");
      feed_ids.push(parameters.feed_ids.split(","));
      parameters.feed_ids = feed_ids.flatten().uniq().join(",");
    }
    
    var new_parameters = $H(old_parameters).merge($H(parameters));
    new_parameters.each(function(key_value) {
      var key = key_value[0];
      var value = key_value[1];
      if(value == null || Object.isUndefined(value) || (typeof(value) == 'string' && value.blank())) {
        new_parameters.unset(key);
      }
    });
    location.hash = "#" + new_parameters.toQueryString();
    
    this.styleFilters();
    
    // Store filters for page reload
    Cookie.set(this.container.getAttribute("id") + "_filters", new_parameters.toQueryString(), 365);
    
    // Reload the item browser
    this.reload();
  },
  
  styleFilters: function() {
    var params = location.hash.gsub('#', '').toQueryParams();
    
    if($("mode_all")) {
  	  var modes = ["all", "unread", "moderated"];
  		if(params.mode) {
  			modes.without(params.mode).each(function(mode) {
  			  $("mode_" + mode).removeClassName("selected")
  			});
			
  			$("mode_" + params.mode).addClassName("selected");
  		} else {
  			modes.without("unread").each(function(mode) {
  			  $("mode_" + mode).removeClassName("selected")
  			});

  			$("mode_unread").addClassName("selected");
  		}
    }
    
    if($("order_newest")) {
  	  var orders = ["newest", "oldest", "strength"];
  		if(params.order) {
  			orders.without(params.order).each(function(order) {
  			  $("order_" + order).removeClassName("selected")
  			});
			
  			$("order_" + params.order).addClassName("selected");
  		} else {
  			orders.without("newest").each(function(order) {
  			  $("order_" + order).removeClassName("selected")
  			});

  			$("order_newest").addClassName("selected");
  		}
    }
    
    var feed_ids = params.feed_ids ? params.feed_ids.split(",") : [];
    $$(".feeds li").each(function(element) {
      var feed_id = element.getAttribute("id").gsub("feed_", "");
      if(feed_ids.include(feed_id)) {
        element.addClassName("selected");
      } else {
        element.removeClassName("selected");
      }
    });
    
    var tag_ids = params.tag_ids ? params.tag_ids.split(",") : [];
    $$(".tags li").each(function(element) {
      var tag_id = element.getAttribute("id").gsub("tag_", "");
      if(tag_ids.include(tag_id)) {
        element.addClassName("selected");
      } else {
        element.removeClassName("selected");
      }
    });
    
    $$(".folder").each(function(folder) {
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
      if(params.text_filter) {
        text_filter.value = params.text_filter;
      } else {
        text_filter.value = "";
        // TODO: Why doesn't this work?
        text_filter.fire("blur");
      }
    }
    
    var clear_selected_filters = $("clear_selected_filters");
    if(clear_selected_filters) {
      if(params.tag_ids || params.feed_ids || params.text_filter) {
        clear_selected_filters.disabled = false;
        clear_selected_filters.value = "Clear Selected Filters";
      } else {
        clear_selected_filters.disabled = true;
        clear_selected_filters.value = "No Filters Selected";
      }
    }
  },
  
  showLoadingIndicator: function(message) {
    var indicator = $(this.container.getAttribute('id') + '_indicator');
    indicator.update(message || "Loading items...");

    var left = this.scrollable.getWidth() / 2 - indicator.getWidth() / 2 + this.scrollable.offsetLeft;
    indicator.style.left = left + "px";

    // var top = this.scrollable.getHeight() / 2 - indicator.getHeight() / 2 - this.scrollable.offsetTop;
    // indicator.style.top = top + "px";
    
    indicator.show();
  },
  
  hideLoadingIndicator: function() {
    $(this.container.getAttribute('id') + '_indicator').hide();
  },
  
  selectItem: function(item) {
    this.deselectItem(this.selectedItem);
    this.selectedItem = $(item);
    this.selectedItem.addClassName('selected');
    this.scrollToItem(item);
  },
  
  deselectItem: function(item) {
    this.selectedItem = null;
    if(item) {
      $(item).removeClassName('selected');
    }
  },
  
  openItem: function(item) {
    this.closeAllItems();
    if(this.selectedItem != $(item)) {
      this.selectItem(item);
    }
    $(item).addClassName("open");
    this.markItemRead(item);
    this.scrollToItem(item);
    this.loadItemDescription(item);
  },
  
  closeItem: function(item) {
    if(item) {
      $(item).removeClassName("open");
      this.closeItemModerationPanel(item);
      this.closeItemTagInformationPanel(item);
    }
  },
  
  closeAllItems: function() {
    $$(".item.open").invoke("removeClassName", "open");
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
  
  openItemModerationPanel: function(item) {
    if(this.selectedItem != $(item)) {
      this.closeItem(this.selectedItem);
      this.selectItem(item);
    }

    $$('.new_tag_form').invoke("hide");

    $('new_tag_form_' + $(item).getAttribute('id')).show();
    this.scrollToItem(item);
    this.loadItemModerationPanel(item);
    
    this.initializeItemModerationPanel(item);
  },
  
  // TODO: need to update this local list when tag controls are clicked so they are always in sync
  initializeItemModerationPanel: function(item) {
    var panel = $(item).down(".new_tag_form");
    var field = panel.down("input[type=text]");
    var list = panel.down(".auto_complete");
    var add = panel.down("input[type=submit]");
    var cancel = panel.down("a");

    if(field && list && add && cancel) {
      if(!this.auto_completers[$(item).getAttribute("id")]) {
        this.auto_completers[$(item).getAttribute("id")] = new Autocompleter.Local(field, list, [], { 
          partialChars: 1, fullSearch: true, choices: this.options.tags.size(), persistent: ["Create Tag: '#{entry}'"], 
          afterUpdateElement: function() { 
            this.closeItemModerationPanel(item);
            // TODO: Move this call into item browser...
            window.add_tag($(item).getAttribute("id"), field.value);
            field.blur();
            field.value = "";
          }.bind(this)
        });
      }
      var used_tags = $$("#tag_controls_" + $(item).getAttribute("id") + " li span.name").collect(function(span) { return span.innerHTML; });
      this.auto_completers[$(item).getAttribute("id")].options.array = this.options.tags.reject(function(tag) {
        return used_tags.include(tag);
      });
      this.auto_completers[$(item).getAttribute("id")].activate();

      field.observe("blur", function() {
        setTimeout(this.closeItemModerationPanel.bind(this, item), 200);
      }.bind(this));
      field.observe("keydown", function(event) {
        if(event.keyCode == Event.KEY_ESC) { this.closeItemModerationPanel(item); }
      }.bind(this));
      field.focus();
      
      add.observe("click", function() {
        this.auto_completers[$(item).getAttribute("id")].selectEntry();
      }.bind(this));

      cancel.observe("click", this.closeItemModerationPanel.bind(this, item));
      
      new Effect.ScrollToInDiv(this.scrollable, list, {duration: 0.3, bottom_margin: 5});
    }
  },
  
  addTag: function(tag) {
    if(!this.options.tags.include(tag)) {
      this.options.tags.push(tag);
      this.options.tags = this.options.tags.sortBy(function(item) { return item.toLowerCase(); });
    }
  },
  
  removeTag: function(tag) {
    this.options.tags = this.options.tags.without(tag)
  },

  closeItemModerationPanel: function(item) {
    var input = $('new_tag_field_' + $(item).getAttribute('id'));
    if(input) { input.blur(); }
    $('new_tag_form_' + $(item).getAttribute('id')).hide();
  },
  
  toggleOpenCloseModerationPanel: function(item) {
    if($('new_tag_form_' + $(item).getAttribute('id')).visible()) {
      this.closeItemModerationPanel(item);
    } else {
      this.openItemModerationPanel(item);
    }
  },
  
  toggleOpenCloseSelectedItemModerationPanel: function() {
    this.toggleOpenCloseModerationPanel(this.selectedItem);
  },
  
  openItemTagInformationPanel: function(item) {
    $('tag_information_' + $(item).getAttribute('id')).show();
    this.scrollToItem(item);
    this.loadItemInformation(item);
  },
  
  closeItemTagInformationPanel: function(item) {
    $('tag_information_' + $(item).getAttribute('id')).hide();
  },
  
  toggleOpenCloseTagInformationPanel: function(item) {
    if($('tag_information_' + $(item).getAttribute('id')).visible()) {
      this.closeItemTagInformationPanel(item);
    } else {
      this.openItemTagInformationPanel(item);
    }
  },
  
  markItemRead: function(item) {
    item = $(item);
    item.addClassName('read');
    item.removeClassName('unread');
    new Ajax.Request('/' + this.options.controller + '/' + item.getAttribute('id').match(/\d+/).first() + '/mark_read', {method: 'put'});
  },
  
  markItemUnread: function(item) {
    item = $(item);
    item.addClassName('unread'); 
    item.removeClassName('read');    
    new Ajax.Request('/' + this.options.controller + '/' + item.getAttribute('id').match(/\d+/).first() + '/mark_unread', {method: 'put'});
  },
  
  toggleReadUnreadItem: function(item) {
    var status = $$('#status_' + $(item).getAttribute('id') + " a").first();
    if (status && $(item).hasClassName('unread')) {
      this.markItemRead(item);
    } else {
      this.markItemUnread(item);      
    }
  },
  
  toggleReadUnreadSelectedItem: function() {
    if(this.selectedItem) {
      this.toggleReadUnreadItem(this.selectedItem);
    }
  },
  
  markAllItemsRead: function() {
    $$('.item.unread').invoke('addClassName', 'read').invoke('removeClassName', 'unread');
    new Ajax.Request('/' + this.options.controller + '/mark_read', {method: 'put'});
  },
  
  scrollToItem: function(item) {
    new Effect.ScrollToInDiv(this.scrollable, $(item).getAttribute('id'), {duration: 0.3});
  },
  
  loadItemDescription: function(item) {
    var body = $("body_" + $(item).getAttribute('id'));
    var url = body.getAttribute('url');
    this.loadData(item, body, url, "Unable to connect to the server to get the item body.", this.closeItem.bind(this));
  },
   
  loadItemModerationPanel: function(item) { 
    var moderation_panel = $("new_tag_form_" + $(item).getAttribute('id')); 
    var url = moderation_panel.getAttribute('url') + "?" + location.hash.gsub("#", ""); 
    this.loadData(item, moderation_panel, url, "Unable to connect to the server to get the moderation panel.", this.closeItemModerationPanel.bind(this));
  },

  loadItemInformation: function(item) {
    var tag_information = $("tag_information_" + $(item).getAttribute('id'));
    var url = tag_information.getAttribute('url');
    this.loadData(item, tag_information, url, "Unable to connect to the server to get the tag information panel.", this.closeItemTagInformationPanel.bind(this));
  },
  
  loadData: function(item, target, url, error_message, error_callback) {
    var item_browser = this;
    var current_item = this.selectedItem;
    
    if(target && target.empty()) {
      target.addClassName("loading");
      new Ajax.Request(url,{
        method: 'get',
          onComplete: function() {
            target.removeClassName("loading");
            if(current_item == $(item)) {
              item_browser.scrollToItem(item);
            }
          },
          onException: function(transport, exception) {
            error_callback(item);
            item_browser.display_error(item, error_message);
          },
          onFailure: function(transport, exception) {
            error_callback(item);
            item_browser.display_error(item, error_message);
          }
      });  
    }
  },
  
  openFeed: function(url) {
    window.open(url + '?' + location.hash.gsub('#', ''));
  },
  
  selectNextItem: function() {
    var next_item;
    if(this.selectedItem) {
      next_item = $(this.selectedItem).nextSiblings().first();
    } else {
      next_item = this.container.descendants().first();
    }
    if(next_item && next_item.hasClassName("item")) {
      this.selectItem(next_item);
    }
  },
  
  selectPreviousItem: function() {
    var previous_item;
    if(this.selectedItem) {
      previous_item = $(this.selectedItem).previousSiblings().first();  
    }
    if(previous_item && previous_item.hasClassName("item")) {
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
    if(next_item && next_item.hasClassName("item")) {
      this.toggleOpenCloseItem(next_item);
    }
  },
  
  openPreviousItem: function() {
    var previous_item;
    if(this.selectedItem) {
      previous_item = $(this.selectedItem).previousSiblings().first();  
    }
    if(previous_item && previous_item.hasClassName("item")) {
      this.toggleOpenCloseItem(previous_item);
    }
  },
  
  display_error: function(item, msg) {
    new ErrorMessage(msg);
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
};
