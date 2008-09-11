// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.

function exceptionToIgnore(e) {
  // Ignore this Firefox error because it just occurs when a XHR request is interrupted.
  return e.name == "NS_ERROR_NOT_AVAILABLE"
}

/* Available Callbacks (in lifecycle order)
 *  - onStarted
 *  - onStartProgressUpdater
 *  - onProgressUpdated
 *  - onCancelled
 *  - onFinished
 */
var Classification = Class.create({
  timeoutMessage: "Timed out trying to start the classifier. Perhaps the server or network are down. You can try again if you like.",
  
  initialize: function(classifier_url, has_changed_tags, options) {
    Classification.instance = this;
    
    this.classifier_url = classifier_url;
    this.has_changed_tags = has_changed_tags;
    
    this.classification_button = $('classification_button');
    this.cancel_classification_button = $('cancel_classification_button');
    this.classification_progress = $('classification_progress');
    this.progress_bar = $('progress_bar');
    this.progress_title = $('progress_title');
    
    this.options = {
      onStarted: function(c) {     
        this.classification_button.hide();
        this.cancel_classification_button.show();

        this.progress_bar.setStyle({width: '0%'});
        this.progress_bar.removeClassName('complete');
        this.progress_title.update("Starting Classifier");
        this.classification_progress.show();

        Content.instance.resizeHeight();
      }.bind(this),
      
      onStartProgressUpdater: function() {
        this.classifier_items_loaded = 0;
      }.bind(this),
      
      onCancelled: function() {
        this.classification_progres.hide();
        this.progress_bar.setStyle({width: '0%'});
        this.progress_title.update("Classify changed tags");
        
        this.cancel_classification_button.hide();
        this.classification_button.show();

        Content.instance.resizeHeight();
      }.bind(this),
      
      onReactivated: function() {
        this.classifier_items_loaded = 0;
        this.classification_button.removeClassName("disabled");
        this.progress_title.update("Classify changed tags");       
      }.bind(this),
      
      onFinished: function() {
        this.classification_progress.hide();
        this.notify("Cancelled")
        this.progress_title.update("Classification Complete");
        this.classification_button.addClassName("disabled");
        if (confirm("Classification has completed.\nDo you want to reload the items?")) {
          itemBrowser.reload();
        }
        $$(".filter_list .tag").each(function(tag) {
          new Ajax.Request("/tags/" + tag.getAttribute('id').match(/\d+/).first() + "/information", { method: 'get',
            onComplete: function(response) {
              tag.title = response.responseHTML;
            }
          });
        });
      }.bind(this),
      
      onProgressUpdated: function(progress) {
        this.progress_bar.setStyle({width: progress.progress + '%'});      
      }.bind(this)
    }
    
    if(!this.has_changed_tags) {
      $('classification_button').addClassName("disabled");
    }
  },
  
  /* puct_confirm == true means that that user has confirmed that they want to 
   * classify some potentially undertrained tags.
   */
  start: function(puct_confirm) {
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
        if (transport.responseText == "The classifier is already running.") {
          this.notify("Started");
          this.startProgressUpdater();
        } else {
          Message.add('error', transport.responseText);
          this.notify('Cancelled');  
        }
      }.bind(this),
      onException: function(request, exception) {
        this.notify('Cancelled');
        if (!exceptionToIgnore(exception)) {
          Message.add('error', "Unable to connect to the web server.");
        }
      }.bind(this),
      onTimeout: function() {
        this.notify("Cancelled");
        Message.add('error', this.timeoutMessage)
      }.bind(this),
      on412: function(response) {
        this.notify('Cancelled');
        if (response.responseJSON) {
          var haveOrHas = "has";
          var tags = response.responseJSON.map(function(t) { return "'" + t + "'";}).sort();
          var tag_names = tags.first();
        
          if (tags.size() > 1) {
            var last = tags.last();
            haveOrHas = "have";
            tag_names = tags.slice(0, tags.size() - 1).join(", ") + ' and ' + last;
          } 
        
          new ConfirmationMessage("You are about to classify " + tag_names + " which " + haveOrHas + " less than 6 positive examples. " + 
                                  "This might not work as well as you would expect.\nDo you want to proceed anyway?", function() {
            this.start(true);
          }.bind(this));
        }
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
        Message.add('error', transport.responseText);
        this.notify('Cancelled');
      },
      onException: function(request, exception) {
        if (!exceptionToIgnore(exception)) {
          Message.add('error', "Exception: " + exception.message);
        }
      }
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
              this.options.onProgressUpdated(this, json);
            }
          }.bind(this),
          onFailure: function(transport) {
            this.notify("Cancelled");
            executer.stop();
            Message.add('error', transport.responseText);
          }.bind(this),
          onException: function(request, exception) {
            this.notify("Cancelled");
            executer.stop();
            if (!exceptionToIgnore(exception)) {
              Message.add('error', "Unable to connect to the web server: " + exception.message);
            }
          }.bind(this),
          onTimeout: function() {
            executer.stop();
            this.notify("Cancelled");
            Message.add('error', this.timeoutMessage);
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
