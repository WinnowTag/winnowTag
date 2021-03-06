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


var activeMenu = null;

var TagContextMenu = Class.create({
  initialize: function(button, tag_id) {
    if (activeMenu && activeMenu.tag_id == tag_id) {
      activeMenu.destroy();
      activeMenu = null;
      return;
    } 
    
    if (activeMenu) {
      activeMenu.destroy();
    }
    
    activeMenu = this;
    this.button = button;
    this.menu = $("tag_context_menu");
    this.tag_id = this.button.getAttribute("tag-id");
    this.path = "/tags/" + this.tag_id;

    if (this.isSubscribedTag()) {
      this.menu.addClassName("subscribed");
    }

    if (this.isArchivedTagWithSubscribers() && this.isArchiveAccount()) {
      this.menu.addClassName("archived_tag_in_archive_account");
    }
    
    if (this.isPublicTag() && !this.isSubscribedTag()) {
      this.menu.addClassName("public"); /* This user's public tag */
    }

    this.tag_li = $("tag_" + tag_id);
    this.tag_li.addClassName("menu-up");

    this.positionMenu();
    this.registerHandlers();
    this.menu.show();
  },
  
  isSubscribedTag: function() {
    return $$("li#tag_" + this.tag_id + ".tag.subscribed").length != 0;
  },
  
  isTagWithSubscriptions: function() {
    return $$("li#tag_" + this.tag_id + ".tag.has_subscriptions").length != 0;
  },

  isPublicTag: function() {
    return $$("li#tag_" + this.tag_id + ".tag.public").length != 0;
  },

  isArchivedTagWithSubscribers: function() {
    return $$("li#tag_" + this.tag_id + ".tag.archived").length != 0;
  },

  isArchiveAccount: function () {
    return $$("li#tag_" + this.tag_id + ".tag.archive_account").length != 0;
  },
  
  getName: function() {
    return $("name_tag_" + this.tag_id).innerHTML;
  },
  
  positionMenu: function() {
    var topPosition = this.button.cumulativeOffset()[1] - this.button.cumulativeScrollOffset()[1] + this.button.getHeight() + 2;
    var contextHeight = this.menu.getHeight();
    var viewportHeight = document.viewport.getHeight();
    
    if (topPosition + contextHeight > viewportHeight - 40) {
       this.menu.style.top = (topPosition - contextHeight - this.button.getHeight()) + "px";
    } else {
      this.menu.style.top = topPosition + "px";
    }
    
    this.menu.style.left = this.button.cumulativeOffset()[0] + "px";
  },
  
  registerHandlers: function() {
    this.destroyHandler = this.destroy.bind(this);
    
    this.clickHandler = this.click.bindAsEventListener(this);
    
    this.menu.select("li").each(function(item) {
      Event.observe(item, "click", this.clickHandler);
    }.bind(this));
    
    Event.observe(document, "click", this.destroyHandler);
  },
  
  click: function(event) {
    var element = event.findElement("li");
    var id = element.getAttribute("id");
    var action = "";
    
    if ((match = /(.*)_menu_item/.exec(id)) != null) {
      action = match[1];
    }
    
    if (this[action]) {
      this[action](event);
    } else {
      alert(action + " not implemented!!");
    }
  },
  
  rename: function(event) {
    /* IE7 & IE8 handling of javascript "prompt" is so horrible, it's better to
     * ask IE users to go to their My Tags page to rename a tag. Depending upon
     * winnowTag's percentage of IE users revealed by by web analytics, later on 
     * we can put in an in-ploace editor or use a javascript/CSS replacement for
     * javascript alert/prompt/confirm. But those approaches are overkill just
     * to fix the single occurrence of this IE problem, at this time. */
    if (/MSIE/.test(navigator.userAgent)) {
      alert(I18n.t("winnow.items.sidebar.use_my_tags_to_rename_tag"));
      return;
    }

    if (!this.isSubscribedTag()) {
      var newName = prompt(I18n.t("winnow.items.sidebar.context_menu_rename"), this.getName());
      if (newName && newName != this.getName()) {
        new Ajax.Request(this.path, {
              parameters: { 'tag[name]': newName },
              method: 'put',
              requestHeaders: { Accept: 'application/json' },
              onSuccess: function(response) {
                var data = response.responseJSON;
                $$(".tag_" + this.tag_id).each(function(e) {
                  e.down('.name').update(data.name);
                  e.up().insertInOrder('.name', e, data.name);
                  new Effect.ScrollToInDiv($("tag_container"), e, 12);
                  if (!(/MSIE/.test(navigator.userAgent))) new Effect.Highlight(e, {
                        queue: 'end', 
                        endcolor: "#FEF3BB",
                        restorecolor: null
                        });
                });
              }.bind(this)
            });
      }
    } else {
      Event.stop(event);
    }
  },
  
  'delete': function() {
    var confirm_message;
    if (this.isArchivedTagWithSubscribers() && this.isArchiveAccount()) {
      alert(I18n.t("winnow.archive.no_deleting_tags_with_subscribers"))
    } else if (this.isSubscribedTag()) {
      confirm_message = I18n.t("winnow.items.sidebar.context_menu_unsubscribe");
      if (this.isArchivedTagWithSubscribers() || (this.isSubscribedTag() && !this.isPublicTag()))
        confirm_message = I18n.t("winnow.items.sidebar.context_menu_unsubscribe_not_public_tag") + '\n\n' + confirm_message;
      if (confirm(confirm_message)) {
        itemBrowser.removeFilters({tag_ids: this.tag_id});
        itemBrowser.styleFilters();
        new Ajax.Request('/tags/' + this.tag_id + '/unsubscribe', {
              asynchronous:true, 
              evalScripts:true, 
              method:'put'
            });
      }
    } else {
      if (this.isTagWithSubscriptions())
        confirm_message = I18n.t("winnow.tags.main.tag_with_subscriptions_destroy_confirm", {tag: this.getName()});
      else
        confirm_message = I18n.t("winnow.tags.main.destroy_confirm", {tag: this.getName()});
      if (confirm(confirm_message)) {
        itemBrowser.removeFilters({tag_ids: this.tag_id});
        itemBrowser.styleFilters();
        new Ajax.Request('/tags/' + this.tag_id, {
              asynchronous:true, 
              evalScripts:true, 
              method:'delete'
            });
      }
    }
  },
  
  'public': function(event) {
    if (!this.isSubscribedTag()) {
      Event.stop(event);
    
      if (this.isPublicTag()) {
        this.menu.removeClassName('public');
      } else {
        this.menu.addClassName('public');
      }
    
      new Ajax.Request('/tags/' + this.tag_id + '/publicize', {
        parameters: {'public': !this.isPublicTag()},
        asynchronous:true,
        evalScripts: true,
        method: 'put',
        onComplete: function() {
          this.destroy();
        }.bind(this)
      });
    } else {
      Event.stop(event);
    }
  },
  
  destroy: function() {
    this.menu.hide();
    this.tag_li.removeClassName("menu-up");
    this.menu.removeClassName("subscribed");
    this.menu.removeClassName("public");
    this.menu.removeClassName("archived_tag_in_archive_account");
    
    Event.stopObserving(document, "click", this.destroyHandler);
    
    this.menu.select("li").each(function(item) {
      Event.stopObserving(item, "click", this.clickHandler);
    }.bind(this));
    
    if (this == activeMenu) {
      activeMenu = null;
    }
  }
});
