// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivative works.
// Please visit http://www.peerworks.org/contact for further information.

var SingleSubmitForm = Class.create({
  initialize: function(form) {
    this.form = $(form);
    this.isSubmitting = false;
    // just grab the first submit
    this.submitButton = this.form.down('input[type=submit]');
    this.form.observe('submit', this.submitForm.bind(this));
  },
  
  submitForm: function(event) {
    if (this.isSubmitting) {
      event.stop();
    } else {
      this.isSubmitting = true;
      this.submitButton.setAttribute('originalValue', this.value);
      this.submitButton.disabled = true;
      this.submitButton.value = this.submitButton.getAttribute('data-disabled_value');
    }
  }
});

document.observe('dom:loaded', function() {
  $$("form.single_submit").each(function(element) {
    new SingleSubmitForm(element);
  });
});
