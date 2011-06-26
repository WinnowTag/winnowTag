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


// Handles switching between the login and request invite forms on the login page.
var Login = Class.create({
  initialize: function() {
    this.login_form = $('login_form');
    this.reminder_form = $('reminder_form');
    this.signup_form = $('signup_form');
    
    if(this.login_form) {
      this.login_form.down(".forgot_password_link").observe("click", this.showReminderForm.bind(this));
      this.showLoginForm();
    }

    if(this.reminder_form) {
      this.reminder_form.down(".forgot_password_link").observe("click", this.showLoginForm.bind(this));
    }
    
    if(this.signup_form) {
      this.signup_form.down('input').focus();
    }
  },

  showLoginForm: function() {
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