// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.

/* Available Callbacks (in lifecycle order)
 *  - onStarted
 *  - onStartProgressUpdater
 *  - onProgressUpdated
 *  - onCancelled
 *  - onFinished
 */
var Classification = Class.create({
  initialize: function(classifier_url, has_changed_tags, options) {
    Classification.instance = this;
    
    this.classifier_url = classifier_url;
    this.has_changed_tags = has_changed_tags;
    
    this.classification_button = $('classification_button');
    this.classification_progress = $('classification_progress');
    this.progress_bar = $('progress_bar');
    this.progress_title = $('progress_title');
    
    this.classification_button.observe("click", this.clickStart.bind(this))
    
    this.options = {
      onStarted: function(c) {     
        this.classification_button.hide();

        this.progress_bar.setStyle({width: '0%'});
        this.progress_title.update(I18n.t("winnow.javascript.classifier.progress_bar.start"));
        this.classification_progress.show();

        Content.instance.resizeHeight();
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
        this.classification_button.show();

        Content.instance.resizeHeight();
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
          new Ajax.Request("/tags/" + tag.getAttribute('id').match(/\d+/).first() + "/information", { method: 'get',
            onComplete: function(response) {
              tag.title = response.responseText;
            }
          });
        });
      }.bind(this)
    }
    
    if(!this.has_changed_tags) {
      this.disableClassification();
    }
  },
  
  disableClassification: function() {
    this.classification_button.addClassName("disabled");
  },
  
  enableClassification: function() {
    this.classification_button.removeClassName("disabled");
  },
  
  clickStart: function() {
      this.start(false);
  },
  /* puct_confirm == true means that that user has confirmed that they want to 
   * classify some potentially undertrained tags.
   */
  start: function(puct_confirm) {
    console.log(puct_confirm)
    if(this.classification_button.hasClassName("disabled")) { return; }
    
    parameters = null;
    if (puct_confirm) {
      parameters = {puct_confirm: 'true'};
    }
      
    new Ajax.Request(this.classifier_url + '/classify', {
      parameters: parameters,
      evalScripts: true,
      onSuccess: function() {
        this.notify('Started');
        this.startProgressUpdater();  
      }.bind(this),
      onFailure: function(transport) {
        if(transport.responseJSON == I18n.t("winnow.javascript.classifier.progress_bar.running")) {
          this.notify("Started");
          this.startProgressUpdater();
        } else {
          Message.add('error', transport.responseJSON);
          this.notify('Cancelled');  
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
              this.options.onProgressUpdated(json);
            }
          }.bind(this),
          onFailure: function(transport) {
            this.notify("Reset");
            executer.stop();
            Message.add('error', transport.responseJSON);
          }.bind(this),
          onTimeout: function() {
            executer.stop();
            this.notify("Reset");
            Message.add('error', I18n.t("winnow.javascript.errors.classifier.timeout"));
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
