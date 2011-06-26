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


// Manages the list of tags shown on the My Tags and Public Tags pages.
var TagsItemBrowser = Class.create(ItemBrowser, {
  initializeTag: function(tag) {
    tag = $(tag);

    var summary = tag.down(".summary");
    var extended = tag.down(".extended");
    var comments = extended.down(".comments");
    
    // Show tag details, comments, and the tag panel.
    summary.observe("click", function(event) {
      if(["a", "input", "textarea"].include(event.element().tagName.toLowerCase())) { return; }

      extended.toggle();
      comments.load(function() {
        tag.down(".summary .comments .unread_comments").update("0");
      }.bind(this));
      var slider = tag.down(".slider");
      if(!slider.bias_slider) {
        slider.bias_slider = new BiasSlider(slider);
      }
    }.bind(this));
    
    // Renaming a tag with an in-place editor.
    var nameToEdit = tag.down("#name_" + tag.id);
    if (nameToEdit) {
      new Ajax.InPlaceEditor(
        nameToEdit,
        nameToEdit.getAttribute("data-update_url"),
        {
          ajaxOptions: {
            method: 'put',
            requestHeaders: { Accept: 'application/json' },
            onSuccess: function(response) {
              var data = response.responseJSON;
              tag.select('.name').invoke('update', data.name);
              tag.down(".feed_links").update(data.feed_links_content);
            }.bind(this)
          },
          paramName: 'tag[name]',
          htmlResponse: false,
          clickToEditText: I18n.t("winnow.tags.main.click_to_edit_name"),
          okText: I18n.t("winnow.general.save")
        }
      );
    }
  },

  insertItem: function($super, item_id, content) {
    $super(item_id, content);
    this.initializeTag(item_id);
  }
});