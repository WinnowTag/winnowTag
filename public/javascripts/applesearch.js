var AppleSearch = Class.create();
AppleSearch.setup = function() {
  if(navigator.userAgent.toLowerCase().indexOf('safari') >= 0) { return; }
  
  $$(".applesearch").each(function(element) {
    new AppleSearch(element);
  });
};

AppleSearch.prototype = {
  initialize: function(element) {
    this.element = element;
    this.element.addClassName("non_safari");
    this.element.applesearch = this;
  
    this.text_input = element.down("input");
    this.text_input.observe("keyup", this.displayClearButton.bind(this));
    this.text_input.observe("focus", this.removePlaceholder.bind(this));
    this.text_input.observe("blur", function() {
      this.displayClearButton();
      this.insertPlaceholder();
    }.bind(this));
    this.text_input.observe("applesearch:blur", function() {
      this.displayClearButton();
      this.insertPlaceholder();
    }.bind(this));

    this.clear_button = element.down('.srch_clear');
    this.clear_button.observe("click", this.clear.bind(this));
  
    this.displayClearButton();
    this.insertPlaceholder();
  },

  displayClearButton: function() {
    if(this.text_input.value.length > 0) {
      this.clear_button.addClassName("clear_button");
    } else {
      this.clear_button.removeClassName("clear_button");
    }
  },
  
  clear: function () {
    this.text_input.value = "";
    this.displayClearButton();
    this.text_input.focus();
  },

  insertPlaceholder: function() {
    if(this.text_input.value == "") {
      this.text_input.addClassName("placeholder");
      // TODO: Why doesn't this work?
      this.text_input.value = this.text_input.getAttribute("placeholder");
    }
  },

  removePlaceholder: function() {
    if(this.text_input.value == this.text_input.getAttribute("placeholder")) {
      this.text_input.value = "";
    }
    this.text_input.removeClassName("placeholder");
  }
}