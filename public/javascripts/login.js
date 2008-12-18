// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var Login = Class.create({
  initialize: function() {
    this.login_form = $('login_form');
    if(this.login_form) {
      this.login_form.down(".invitation a").observe("click", this.showInviteForm.bind(this));
      this.login_form.down(".forgot_password_link").observe("click", this.showReminderForm.bind(this));
      this.login_form.down('input#login').focus();
    }
    this.invite_form = $('invite_form');
    if(this.invite_form) {
      this.invite_form.down(".login a").observe("click", this.showLoginForm.bind(this));
    }

    this.reminder_form = $('reminder_form');
    if(this.reminder_form) {
      this.invite_form.down(".login a").observe("click", this.showLoginForm.bind(this));
      this.reminder_form.down(".forgot_password_link").observe("click", this.showLoginForm.bind(this));
    }

    this.signup_form = $('signup_form');
    if(this.signup_form) {
      this.signup_form.down('input#user_login').focus();
    }
  },
  
  showInviteForm: function() {
    this.login_form.hide();
    this.invite_form.show();
  },
  
  showLoginForm: function() {
    this.invite_form.hide();
    this.reminder_form.hide();
    this.login_form.show();
  },
  
  showReminderForm: function() {
    this.login_form.hide();
    this.reminder_form.show();
  }
});

document.observe('dom:loaded', function() {
  if(document.body.match("#login")) {
    new Login();
  }
});