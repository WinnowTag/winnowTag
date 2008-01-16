// Copyright (c) 2007 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please contact info@peerworks.org for further information.
//
// Functions that control the feed item browser interface
var classification = null;

function exceptionToIgnore(e) {
	// Ignore this Firefox error because it just occurs when a XHR request is interrupted.
	return e.name == "NS_ERROR_NOT_AVAILABLE"
}

function cancelClassification() {
	if (classification) {
		classification.cancel();
	}
	
	classification = null;
}

var BiasSlider = Class.create();
BiasSlider.prototype = Object.extend(Control.Slider.prototype, {
	setDisabled: function() {
		this.disabled = true;
		this.track.addClassName('disabled');		
	},
	setEnabled: function() {
		this.disabled = false;
		this.track.removeClassName('disabled');
	},
	sendUpdate: function(bias, tag_id) {
	  new Ajax.Request("/tags/" + tag_id + "?tag[bias]=" + bias, {method: "PUT"});
	}
});

var Classification = Class.create();

/** Creates a Classification instance configured to be integrated
 *  with the ItemBrowser
 */
Classification.createItemBrowserClassification = function(classifier_url) {	
	return new Classification(classifier_url, {
			onStarted: function(c) {				
				$('progress_bar').style.width = "0%";
				$('progress_title').update("Classifying changed tags");
			},
			onStartProgressUpdater: function(c) {
				c.classifier_items_loaded = 0;
			},
			onShowProgressBar: function(c) {
			  $('classification_button').hide();
			  $('cancel_classification_button').show();
				$('progress_bar').removeClassName('complete');
				$('classification_progress').show();
				$('progress_title').update("Starting Classifier");
			},
			onReset: function() {
			  
			},
			onCancelled: function(c) {
				$('cancel_classification_button').hide();
				$('classification_button').show();
				$('progress_bar').setStyle({width: '0%'});
				$('progress_title').update("Classify changed tags");					
			},
			onReactivated: function(c) {
				c.classifier_items_loaded = 0;
				$('classification_button').disabled = false;
				$('progress_title').update("Classify changed tags");					
			},
			onFinished: function(c) {
				c.options.onCancelled(c);
				$('progress_title').update("Classification Complete");
				$('classification_button').disabled = true;
				if (confirm("Classification has completed.\nDo you want to reload the items?")) {
				  itemBrowser.reload();
				}
			},
			onProgressUpdated: function(c, progress) {
				$('progress_bar').setStyle({width: progress.progress + '%'});			
			}						
		});
};

/**
 *
 *  Available Callbacks (in lifecycle order)
 *
 *   - onStart
 *   - onShowProgressBar
 *   - onStarted
 *   - onStartProgressUpdater
 *   - onProgressUpdated
 *   - onCancelled
 *   - onFinished
 *   - onReset
 */
Classification.prototype = {
	timeoutMessage: "Timed out trying to start the classifier.  Perhaps the server or network are down. You can try again if you like.",
	initialize: function(classifier_url, options) {
		this.classifier_url = classifier_url;
		this.options = {}
		Object.extend(this.options, options || {});
		classification = this;
	},
	
	start: function() {
		this.notify('Start');		
		this.showProgressBar();
						
		new Ajax.Request(this.classifier_url + '/classify', {
			evalScripts: true,
			onSuccess: function() {
				this.notify('Started');
				this.startProgressUpdater();				
			}.bind(this),
			onFailure: function(transport) {
				if (transport.responseText == "The classifier is already running.") {
					this.notify("Started");
					this.startProgressUpdater();
				} else {
					new ErrorMessage(transport.responseText);
					this.notify('Cancelled');	
				}
			}.bind(this),
			onException: function(request, exception) {
			  this.notify('Cancelled');
				if (!exceptionToIgnore(exception)) {
					new ErrorMessage("Unable to connect to the web server.");
				}
			}.bind(this),
			onTimeout: function() {
				this.notify("Cancelled");
				new ErrorMessage(this.timeoutMessage)
			}.bind(this)
		});
	},
	
	cancel: function() {
		this.progressUpdater.stop();
		this.reset();
				
		new Ajax.Request(this.classifier_url + '/cancel?no_redirect=true', {
			onComplete: function() {
				this.notify('Cancelled');
			}.bind(this),
			onFailure: function(transport) {
				alert(transport.responseText);
				this.notify('Cancelled');
			},
			onException: function(request, exception) {
				if (!exceptionToIgnore(exception)) {
					alert("Exception: " + exception.message);
				}
			}
		});		
	},
	
	showProgressBar: function() {
		if (this.options.onShowProgressBar) {
			this.options.onShowProgressBar(this);
		}	
	},
		
	startProgressUpdater: function() {
		this.notify('StartProgressUpdater');
		this.progressUpdater = new PeriodicalExecuter(function(executer) {
			if (!this.loading) {
				this.loading = true;
				new Ajax.Request(this.classifier_url + '/status', {
					onComplete: function(transport, json) {					
						this.loading = false;
						if (!json || json.progress >= 100) {
							executer.stop();
							this.notify('Finished');
						}
					}.bind(this),
					onSuccess: function(transport, json) {
						if (this.options.onProgressUpdated) {
							this.options.onProgressUpdated(this, json);
						}
					}.bind(this),
					onFailure: function(transport) {
						this.notify("Cancelled");
						executer.stop();
						new ErrorMessage(transport.responseText);
					}.bind(this),
					onException: function(request, exception) {
					  this.notify("Cancelled");
						executer.stop();
						if (!exceptionToIgnore(exception)) {
							new ErrorMessage("Unable to connect to the web server: " + exception.message);
						}
					}.bind(this),
					onTimeout: function() {
						executer.stop();
						this.notify("Cancelled");
						new ErrorMessage(this.timeoutMessage);
					}.bind(this)
				});
			}
		}.bind(this), 2);
	},
	notify: function(event) {
		if (this.options['on' + event]) {
			this.options['on' + event](this);
		}
	}
};

var ItemBrowser = Class.create();
/** Provides the ItemBrowser functionality.
 *
 *  The Item Browser is a scrollable view over the entire list of items
 *  in the database.  Items are lazily loaded into the browser as the 
 *  users scrolls the view around.
 */
ItemBrowser.prototype = {
	/** Initialization function.
	 *
	 *  @param feed_item_container The element or id of the feed item
	 *         container div.  This is the div that lies within scrollable
	 *         div.  The feed item container div holds the feed item elements.
	 *         The ItemBrowser will look for another element with the id
	 *         feed_item_container + '_scrollable' that will be used as the
	 *         scrollable div.
	 *
	 *  @param options A hash of options.  Supported options are:
	 *         - pruning_threshold: The number of items that can be loaded into
	 *                              the browser before pruning occurs.
	 *         - update_threshold: The minimum number of items that will be fetched in
	 *                             an update for that update to occur.
	 *
	 */
	initialize: function(feed_item_container, options) {
		this.options = {
			pruning_threshold: 500,
			update_threshold: 8
		};
		Object.extend(this.options, options || {});
		
		document.observe('keypress', this.keypress.bindAsEventListener(this));
		
		this.update_queue = new Array();
		
		// counts of the number of pruned items
		this.pruned_items = 0;
		
		// Flag for loading item - so we don't load them more than once at a time.
		this.loading = false;		
		this.feed_items_container = $(feed_item_container);
		this.feed_items_scrollable = $('content');

		this.initializeItemList();
		
		var self = this;
		Event.observe(this.feed_items_scrollable, 'scroll', function() { self.scrollFeedItemView(); });
		
		if(location.hash.gsub('#', '').blank() && Cookie.get("filters")) {
		  this.setFilters(Cookie.get("filters").toQueryParams());
		} else {
		  this.setFilters(location.hash.gsub('#', '').toQueryParams());
		}
	},
	
	/** Called to initialize the internal list of items from the items loaded into the feed_item_container.
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
		
		this.feed_items_container.getElementsByClassName('item').each(function(fi) {
			this.items.insert(this.items.length, fi.getAttribute('id'), fi.getAttribute('position'), fi);
		}.bind(this));
	},
	
	itemHeight: function() {
		if (this.items[0]) {
			return this.items[0].element.offsetHeight;
		} else {
		  return 0;
		}
	},
	
	/** Updates the display of the feed item count.
	 */	
	updateFeedItemCount: function() {
		$('feed_item_count').update("About " + this.items.compact().length + " items");
	},
	
	/** Returns the number of items in the viewable area of the scrollable container */
	numberOfItemsInView: function() {
		return Math.round(this.feed_items_scrollable.getHeight() / this.itemHeight());
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
	},
	
	/** Updates the initial spacer's height to cover the total number of items minus the number of 
	 *  items already loaded.
	 */
	updateInitialSpacer: function() {
		var height = (this.total_items - this.items.length) * this.itemHeight();
		var spacer = this.feed_items_container.down(".item_spacer");
		
		if (!spacer) {
			new Insertion.Bottom(this.feed_items_container, '<div class="item_spacer"></div>');
			spacer = this.feed_items_container.down(".item_spacer");
		}
		
		spacer.setStyle({height: '' + height + 'px'});		
	},
	
	/** Responds to scrolling events on the feed_item_scrollable.
	 *
	 *  When a scrolling event occurs a function will be registered with
	 *  a 500ms delay to call the updateFeedItems method. Subsequent scrolling
	 *  events within 500ms will clear that function and register a new one.
	 *  The reason for this is that the scroll event is dispatched constantly by 
	 *  the browser as the viewport is scrolled, so the prevent multiple updates
	 *  being requested we only issue an update when the user has stopped scrolling
	 *  for at least 500ms.
	 */
	scrollFeedItemView: function() {
		if (this.item_loading_timeout) {			
			clearTimeout(this.item_loading_timeout);
		}
		
		var scrollTop = this.feed_items_scrollable.scrollTop;
		// bail out of scrollTop is zero - this prevents prematurely 
		// getting items when the list is cleared.
		if (scrollTop == 0) {return;}
		var offset = Math.floor(scrollTop / this.itemHeight());
		
		this.item_loading_timeout = setTimeout(function() {
			if (this.loading) {
			  var self = this;
				this.update_queue.push(function() {
				  self.updateFeedItems({offset: offset});
				});
			} else {
				this.updateFeedItems({offset: offset});				
			}
		}.bind(this), 300);
	}, 
	
	/** Creates the update URL from a list of options. */
	buildUpdateURL: function(parameters) {
		return '/feed_items?' + $H(location.hash.gsub('#', '').toQueryParams()).merge($H(parameters)).toQueryString();
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
	 *  In it's normal mode, updateFeedItems accepts an offset parameter as one
	 *  of the options.  This parameter is interpreted as the position of the
	 *  top of the scroll viewport, it then attempts to gets item to cover the
	 *  previous half page, the current page and the first half of the next page.
	 *
	 *  The second mode is the incremental mode, which currently uses the explicit
	 *  offset and limit specified in the arguments.  Also in the incremental mode
	 *  if the number of items currently loaded is greater than the pruning_threshold,
	 *  no items will be fetched, just the counts are updatd, i.e. the total_items 
	 *  and the tag count filters.
	 */
	updateFeedItems: function(options) {
		if (this.loading) {
			return;
		}
		this.loading = true;
		
		var update_options = Object.clone(options);
		
		if (options && options.incremental && this.items.length >= this.options.pruning_threshold) {
			update_options.count_only = true;
			// Set loading to false because this request won't trigger an item load
			this.loading = false;
		}
		
		var do_update = false;
		// This is the standard update method.
		//
		// Start half a page ahead and behind the current page and 
		// 'squeeze' in until we have a set of items to load.		 
		if (update_options && !(update_options.incremental || update_options.count_only)) {
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
				
		if (do_update || update_options.incremental) {
			if (!update_options.count_only) {
        this.showLoadingIndicator();
			}
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
				this.updateFeedItemCount();
				if (!options.count_only) {
          this.hideLoadingIndicator();
				}
				this.loading = false;
				this.updateFromQueue();
			}.bind(this),
			onFailure: function() {
				alert("Failure!");
			},
			onException: function(request, exception) {
				if (!exceptionToIgnore(exception)) {
					alert("Exception: " + exception.toString());
				}
			}
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
			this.feed_items_container.scrollTop -= totalHeight;
		}
	},
	
	/** Inserts an item into the feed item container.
	 *
	 *  Items are inserted by using their position within the list of items to
	 *  find how many items not yet loaded come before and after the new item.
	 *  This empty space is filled with a spacer div whose height is equal to the
	 *  number of items that would fit in the gap * the height of a feed item.
	 *  This ensures that each feed item is positioned both in the items list and
	 *  the feed item container that corresponds to their position in the list
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
				existing_spacer = this.feed_items_container.immediateDescendants().first();
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
				new Insertion.Bottom('feed_items', first_spacer_content + content + next_spacer_content);
			}
			this.items[position] = {element: $(item_id), position: $(item_id).getAttribute('position')};
			this.items[item_id] = true;
		}
	},
	
	/** Inserts a item in it's correct position.
	 *
	 *  This function is used during the incremental update process to ensure that items
	 *  which come in during classification are placed in the correct order.  Ordering is done
	 *  by the position attribute.
	 */
	insertInOrder: function(item_id, position, content) {		
		if (!this.items[item_id] && this.items.length == 0) {
			new Insertion.Top(this.feed_items_container, content);
			this.items.insert(0, item_id, position, $(item_id));
		} else if (!this.items[item_id]) {
			var inserted = false;
			var skippedOver = null;
			
			for (var i = this.items.length - 1; i >= 0; i--) {
				if (!this.items[i]) {
					skippedOver = i;					
				} else if (this.items[i].position >= position) {
					inserted = true;							
					if (skippedOver) {
						this.removeEmptySpaceAt(skippedOver);
					}
					new Insertion.After(this.items[i].element, content);
					this.items.insert(i + 1, item_id, position, this.items[i].element.next());	
					break;
				} 
			}
			
			if (!inserted) {
				if (skippedOver) {
					this.removeEmptySpaceAt(skippedOver);
				}
				new Insertion.Before(this.items[0].element, content);
				this.items.insert(0, item_id, position, $(item_id));

			}						
		}
		
		this.updateInitialSpacer();
	},
	
	removeEmptySpaceAt: function(index) {
		if (this.items[index - 1]) {
			var space = this.items[index - 1].element.nextSiblings().first();
			if (space) {
				space.setStyle({height: space.getHeight() - this.itemHeight() + 'px'});
			}
		}
		
		this.items.splice(index, 1);
	},

	/** Clears all the items. */
	clear: function() {
		this.feed_items_container.update('');
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
	
	setFilters: function(parameters) {
	  $$(".feeds li").invoke("removeClassName", "selected");
	  $$(".tags li").invoke("removeClassName", "selected");
	  $$(".folder").invoke("removeClassName", "selected");
	  
	  location.hash = " "; // This needs to be set to a space otherwise safari does not register the change
	  this.addFilters(parameters);
	},
	
	addFilters: function(parameters) {
	  // Update location.hash
	  var new_parameters = $H(location.hash.gsub('#', '').toQueryParams()).merge($H(parameters));
	  new_parameters.each(function(key_value) {
      var key = key_value[0];
      var value = key_value[1];
	    if(value == null || Object.isUndefined(value) || (typeof(value) == 'string' && value.blank())) {
	      new_parameters.unset(key);
	    }
	  });
	  location.hash = "#" + new_parameters.toQueryString();

    // Update styles on selected items
    var params = new_parameters.toQueryString().toQueryParams();
	  if(params.feed_ids) {
	    params.feed_ids.split(",").each(function(feed_id) {
	      $$("#feed_" + feed_id).invoke("addClassName", "selected");
	    });
	  }
	  if(params.tag_ids) {
	    params.tag_ids.split(",").each(function(tag_id) {
	      $$("#tag_" + tag_id).invoke("addClassName", "selected");
	    });
	  }
	  if(params.folder_id) {
	    $('folder_' + params.folder_id).addClassName("selected");
      // $('folder_' + params.folder_id).select(".feeds li").each(function(element) {
      //   $$("#" + element.getAttribute("id")).invoke("addClassName", "selected");
      // });
	  }
	  
	  // Store filters for page reload
	  Cookie.set("filters", new_parameters.toQueryString(), 365);
	  
	  // Reload the item browser
	  this.reload();
	},
	
	showLoadingIndicator: function(message) {
	  var indicator = $('feed_items_indicator')
	  indicator.update(message || "Loading feed items...");

	  var left = this.feed_items_scrollable.getWidth() / 2 - indicator.getWidth() / 2 + this.feed_items_scrollable.offsetLeft;
    indicator.style.left = left + "px";

    // var top = this.feed_items_scrollable.getHeight() / 2 - indicator.getHeight() / 2 - this.feed_items_scrollable.offsetTop;
    // indicator.style.top = top + "px";
    
	  indicator.show();
	},
	
	hideLoadingIndicator: function() {
	  $('feed_items_indicator').hide();
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
		if(this.selectedItem != $(item)) {
			this.closeItem(this.selectedItem);
			this.selectItem(item);
		}
		$('open_' + $(item).getAttribute('id')).show();
		this.markItemRead(item);
		this.scrollToItem(item);
		this.loadItemDescription(item);
	},
	
	closeItem: function(item) {
		if(item) {
			$('open_' + $(item).getAttribute('id')).hide();
			this.closeItemModerationPanel(item);
			this.closeItemTagInformationPanel(item);
		}
	},
	
	toggleOpenCloseItem: function(item) {
		if($('open_' + $(item).getAttribute('id')).visible() && $('body_' + $(item).getAttribute('id')).visible()) {
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

		var container = $('new_tag_form_' + $(item).getAttribute('id'));
		container.show();
		this.scrollToItem(item);
	  this.loadItemModerationPanel(item);

		if(!container.empty()) {
		  $('new_tag_field_' + $(item).getAttribute('id')).focus();
		}
	},
	
	closeItemModerationPanel: function(item) {
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
    new Ajax.Request('/feed_items/' + item.getAttribute('id').match(/\d+/).first() + '/mark_read', {method: 'put'});
	},
	
	markItemUnread: function(item) {
	  item = $(item);
    item.addClassName('unread'); 
    item.removeClassName('read');    
    new Ajax.Request('/feed_items/' + item.getAttribute('id').match(/\d+/).first() + '/mark_unread', {method: 'put'});
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
		new Ajax.Request('/feed_items/mark_read', {method: 'put'});
	},
	
	scrollToItem: function(item) {
		new Effect.ScrollToInDiv(this.feed_items_scrollable, $(item).getAttribute('id'), {duration: 0.3});
	},
	
	loadItemDescription: function(item) {
		var body = $("body_" + $(item).getAttribute('id'));
		var url = body.getAttribute('url');
		this.loadData(item, body, url, "Unable to connect to the server to get the item body.", this.closeItem.bind(this));
	},
	
	loadItemInformation: function(item) {
		var tag_information = $("tag_information_" + $(item).getAttribute('id'));
		var url = tag_information.getAttribute('url');
		this.loadData(item, tag_information, url, "Unable to connect to the server to get the tag information panel.", this.closeItemTagInformationPanel.bind(this));
	},
	
	loadItemModerationPanel: function(item) {
		var moderation_panel = $("new_tag_form_" + $(item).getAttribute('id'));
		var url = moderation_panel.getAttribute('url');
		this.loadData(item, moderation_panel, url, "Unable to connect to the server to get the moderation panel.", this.closeItemModerationPanel.bind(this));
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
	
	selectNextItem: function() {
		var next_item;
		if(this.selectedItem) {
			next_item = $(this.selectedItem).nextSiblings().first();
		} else {
			next_item = this.feed_items_container.descendants().first();
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
			next_item = this.feed_items_container.descendants().first();
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
