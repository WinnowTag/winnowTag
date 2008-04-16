Localization.define do |l|
  # app/controllers/account_controller.rb
  l.store :profile_update,              "Information Updated"
  l.store :credentials_invalid,         "Invalid credentials. Please try again."
  l.store :update_password,             "Please update your password"
  l.store :reminder_invalid,            "Invalid reminder code"
  l.store :reminder_sent,               "A password reminder has been sent"
  l.store :invitation_submitted,        "Your invitation request has been submitted"
  l.store :account_activated,           "Your account has been activated."
  l.store :account_activation_failed,   "Unable to activate the account. Did you provide the correct information?"
  l.store :login_invalid,               "Unable to activate the account. Did you provide the correct information?"
  
  # app/controllers/classifier_controller.rb
  l.store :classifier_running,          "The classifier is already running."
  l.store :classifier_not_running,      "No classification process running"
  l.store :tags_not_changed,            "There are no changes to your tags"
  
  # app/controllers/feeds_controller.rb
  l.store :feed_not_found,              "We couldn't find this feed in any of our databases. Maybe it has been deleted or never existed. If you think this is an error, please contact us."
  l.store :collector_down,              "Sorry, we couldn't find the feed and the main feed database couldn't be contacted. We are aware of this problem and will fix it soon. Please try again later."
  l.store :feed_added,                  "Thanks for adding the feed from %s. We will fetch the items soon and we'll let you know when it is done. The feed has also been added to your feeds folder in the sidebar."
  l.store :feed_existed,                "We already have the feed from %s, however we will update it now and we'll let you know when it is done. The feed has also been added to your feeds folder in the sidebar."
  l.store :feeds_imported, :plural =>   "Imported %d feeds from your OPML file", 
                           :singular => "Imported %d feed from your OPML file"
end
