// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivative works.
// Please visit http://www.peerworks.org/contact for further information.

// Handles switching between the login and request invite forms on the login page.
var Login = Class.create({
  initialize: function() {
    this.login_form = $('login_form');
    this.invite_form = $('invite_form');
    this.reminder_form = $('reminder_form');
    this.signup_form = $('signup_form');
    
    if(this.login_form) {
      this.login_form.down(".invitation a").observe("click", this.showInviteForm.bind(this));
      this.login_form.down(".forgot_password_link").observe("click", this.showReminderForm.bind(this));
      this.showLoginForm();
    }
    
    if(this.invite_form) {
      this.invite_form.down(".login a").observe("click", this.showLoginForm.bind(this));
      
      if(this.invite_form.down(".errorExplanation")) {
        this.showInviteForm();
      }
    }
    
    if(this.reminder_form) {
      this.reminder_form.down(".forgot_password_link").observe("click", this.showLoginForm.bind(this));
    }
    
    if(this.signup_form) {
      this.signup_form.down('input').focus();
    }
  },
  
  showInviteForm: function() {
    this.login_form.hide();
    this.invite_form.show();
    this.invite_form.down('input').focus();
  },
  
  showLoginForm: function() {
    this.invite_form.hide();
    this.reminder_form.hide();
    this.login_form.show();
    this.login_form.down('input').focus();
  },
  
  showReminderForm: function() {
    this.login_form.hide();
    this.reminder_form.show();
    this.reminder_form.down('input').focus();
  }
});

document.observe('dom:loaded', function() {
  if($(document.body).match("#login")) {
    new Login();
  }
});