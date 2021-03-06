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


/* When a user invokes classification from the items page, this class sends
 * the request to the classifier. It then keeps the user aware of progress
 * and any errors that might occur. It does this through its callbacks.
 * 
 * Available Callbacks (in lifecycle order)
 *  - onStarted
 *  - onStartProgressUpdater
 *  - onProgressUpdated
 *  - onReset
 *  - onFinished
 */
var Classification = Class.create({
  initialize: function(classify_url, status_url, has_changed_tags, options) {
    Classification.instance = this;
    
    this.classify_url = classify_url;
    this.status_url = status_url;
    this.has_changed_tags = has_changed_tags;
    
    this.classification_controls = $('classification_controls');
    this.classification_button = $('classification_button');
    this.classification_progress = $('classification_progress');
    this.progress_bar = $('progress_bar');
    this.progress_title = $('progress_title');
    
    this.classification_button.observe("click", this.clickStart.bind(this))
    
    this.options = {
      onStarted: function(c) {     
        this.classification_controls.hide();

        this.progress_bar.setStyle({width: '0%'});
        this.progress_title.update(I18n.t("winnow.javascript.classifier.progress_bar.start"));
        this.classification_progress.show();
      }.bind(this),
      
      onStartProgressUpdater: function() {
        this.classifier_items_loaded = 0;
      }.bind(this),
      
      onProgressUpdated: function(progress) {
        this.progress_bar.setStyle({width: progress.progress + '%'});      
      }.bind(this),
      
      onReset: function() {
        this.classification_progress.hide();
        this.progress_bar.setStyle({width: '0%'});
        this.progress_title.update(I18n.t("winnow.javascript.classifier.progress_bar.cancel"));        
        this.classification_controls.show();
      }.bind(this),
      
      onFinished: function() {
        this.classification_progress.hide();
        this.notify("Reset");
        this.progress_title.update(I18n.t("winnow.javascript.classifier.progress_bar.finish"));
        this.disableClassification();
        if(confirm(I18n.t("winnow.javascript.classifier.progress_bar.reload"))) {
          itemBrowser.reload();
        }
        $$(".filter_list .tag").each(function(tag) {
          var tagIDNumber = tag.getAttribute("id").gsub("tag_", "");
          if (tagIDNumber != 0) { // Skip the request for tag list control "See All Tags"
            new Ajax.Request("/tags/" + tagIDNumber + "/information.json", { method: 'get',
                onComplete: function(response) {
                  try {
                    if (response.status == 200) {
                      tag.title = response.responseJSON.tooltip;
                      tag.setAttribute("item_count", response.responseJSON.item_count);
                      tag.setAttribute("pos_count", response.responseJSON.positive_count);
                      tag.setAttribute("neg_count", response.responseJSON.negative_count);

                      if (tagIDNumber == $A(itemBrowser.filters.tag_ids.split(",")).first())
                        itemBrowser.showDemoTagInfo();
                    }
                  } catch(e) {}
                }
            });
          }
        });
      }.bind(this)
    }
    
    if(!this.has_changed_tags) {
      this.disableClassification();
    }
  },
  
  disableClassification: function() {
    this.classification_button.addClassName("disabled");
    this.classification_button.title = I18n.t('winnow.items.footer.start_classifier_disabled_tooltip')

  },
  
  enableClassification: function() {
    this.classification_button.removeClassName("disabled");
    this.classification_button.title = I18n.t('winnow.items.footer.start_classifier_tooltip')
  },
  
  clickStart: function() {
      this.start(false);
  },
  /* puct_confirm == true means that that user has confirmed that they want to 
   * classify some potentially undertrained tags.
   */
  start: function(puct_confirm) {
    if(this.classification_button.hasClassName("disabled")) { return; }
    
    parameters = null;
    if (puct_confirm) {
      parameters = {puct_confirm: 'true'};
    }
      
    new Ajax.Request(this.classify_url, {
      parameters: parameters,
      evalScripts: true,
      onSuccess: function() {
        this.notify('Started');
        this.startProgressUpdater();  
      }.bind(this),
      onFailure: function(transport) {
        if(transport.responseJSON == I18n.t("winnow.javascript.classifier.progress_bar.runningHARDCODED")) {
          this.notify("Started");
          this.startProgressUpdater();
        } else {
          // TODO: Don't use response.JSON in messages to user, they have outdated terminology and are not in I18n.'
          Message.add('error', transport.responseJSON);
          this.notify('Reset');
        }
      }.bind(this),
      onTimeout: function() {
        this.notify("Reset");
        Message.add('error', I18n.t("winnow.javascript.errors.classifier.timeout"));
      }.bind(this),
      on412: function(response) {
        this.notify('Reset');
        if (response.responseJSON) {
          new ConfirmationMessage(response.responseJSON, function() {
            this.start(true);
          }.bind(this));
        }
      }.bind(this)
    });
  },
    
  startProgressUpdater: function() {
    this.notify('StartProgressUpdater');
    this.progressUpdater = new PeriodicalExecuter(function(executer) {
      if (!this.loading) {
        this.loading = true;
        new Ajax.Request(this.status_url, {
          onComplete: function(transport, json) {          
            this.loading = false;
            if (!json || json.progress >= 100) {
              executer.stop();
              this.notify('Finished');
            }
          }.bind(this),
          onSuccess: function(transport, json) {
            if (this.options.onProgressUpdated) {
              this.options.onProgressUpdated(json);
            }
          }.bind(this),
          onFailure: function(transport) {
            this.notify("Reset");
            executer.stop();
            Message.add('error', transport.responseJSON);
          }.bind(this),
          onTimeout: function() {
            Message.add('warning', I18n.t("winnow.javascript.errors.classifier.winnowtag_communication_slow"));
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
});
