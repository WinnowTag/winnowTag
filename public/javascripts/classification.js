// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.

function exceptionToIgnore(e) {
  // Ignore this Firefox error because it just occurs when a XHR request is interrupted.
  return e.name == "NS_ERROR_NOT_AVAILABLE"
}

var Classification = Class.create();

Classification.instance = null;

Classification.cancel = function() {
  if(Classification.instance) {
    Classification.instance.cancel();
    Classification.instance = null
  }
}

/** Creates a Classification instance configured to be integrated
 *  with the ItemBrowser
 */
Classification.startItemBrowserClassification = function(classifier_url, puct_confirm) {  
  Classification.instance = new Classification(classifier_url, {
    onStarted: function(c) {        
      $('progress_bar').style.width = "0%";
      $('progress_title').update("Classifying changed tags");
      $('classification_button').hide();
      $('cancel_classification_button').show();
      $('progress_bar').removeClassName('complete');
      $('classification_progress').show();
      $('progress_title').update("Starting Classifier");
    },
    onStartProgressUpdater: function(c) {
      c.classifier_items_loaded = 0;
    },
    onShowProgressBar: function(c) {
      
    },
    onReset: function() {
      
    },
    onCancelled: function(c) {
      $('classification_progress').hide();
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
      $('classification_progress').hide();
      c.options.onCancelled(c);
      $('progress_title').update("Classification Complete");
      $('classification_button').disabled = true;
      if (confirm("Classification has completed.\nDo you want to reload the items?")) {
        itemBrowser.reload();
      }
      $$(".tag .training").each(function(training) {
        var tag = training.up(".tag");

        training.update("");
        training.addClassName("loading");
        new Ajax.Updater(training, "/tags/" + tag.getAttribute('id').match(/\d+/).first() + "/information", { method: 'get',
          onComplete: function() {
            training.removeClassName("loading");
          }
        });
      });
    },
    onProgressUpdated: function(c, progress) {
      $('progress_bar').setStyle({width: progress.progress + '%'});      
    }            
  });
  Classification.instance.start(puct_confirm);
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
  
  /* puct_confirm == true means that that user has confirmed that they want to 
   * classify some potentially undertrained tags.
   */
  start: function(puct_confirm) {
    this.notify('Start');    
        
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
            classification = Classification.startItemBrowserClassification('/classifier', true);
          });
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
};