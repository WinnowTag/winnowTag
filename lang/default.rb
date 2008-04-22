Localization.define do |l|
  # app/controllers/account_controller.rb
  l.store :profile_update,                        "Information Updated"
  l.store :credentials_invalid,                   "Invalid credentials. Please try again."
  l.store :update_password,                       "Please update your password"
  l.store :reminder_invalid,                      "Invalid reminder code"
  l.store :reminder_sent,                         "A password reminder has been sent"
  l.store :invitation_submitted,                  "Your invitation request has been submitted"
  l.store :account_activated,                     "Your account has been activated"
  l.store :account_activation_failed,             "Unable to activate the account. Did you provide the correct information?"
  l.store :login_invalid,                         "Unable to activate the account. Did you provide the correct information?"

  # app/controllers/classifier_controller.rb
  l.store :classifier_running,                    "The classifier is already running"
  l.store :classifier_not_running,                "No classification process running"
  l.store :tags_not_changed,                      "There are no changes to your tags"

  # app/controllers/feeds_controller.rb
  l.store :feed_not_found,                        "We couldn't find this feed in any of our databases. Maybe it has been deleted or never existed. If you think this is an error, please contact us."
  l.store :collector_down,                        "Sorry, we couldn't find the feed and the main feed database couldn't be contacted. We are aware of this problem and will fix it soon. Please try again later."
  l.store :feed_added,                            "Thanks for adding the feed from %s. We will fetch the items soon and we'll let you know when it is done. The feed has also been added to your feeds folder in the sidebar."
  l.store :feed_existed,                          "We already have the feed from %s, however we will update it now and we'll let you know when it is done. The feed has also been added to your feeds folder in the sidebar."
  l.store :feeds_imported,           :singular => "Imported %d feed from your OPML file",
                                     :plural   => "Imported %d feeds from your OPML file"

  # app/controllers/item_protection_controller.rb
  l.store :item_protection_status,                "Unable to fetch protection status from the collector"
  l.store :item_protection_rebuild,               "Could not rebuild item protection: %s"

  # app/controllers/messages_controller.rb
  l.store :message_created,                       "Message was successfully created"
  l.store :message_updated,                       "Message was successfully updated"

  # app/controllers/taggings_controller.rb
  l.store :bad_method,                            "Bad Request. Should be POST. Please report this bug. Make sure you have Javascript enabled too!"
  l.store :bad_params,                            "Bad Request. Missing Parameters. Please report this bug. Make sure you have Javascript enabled too!"
  l.store :tagging_failed,                        "Tagging Failed"

  # app/controllers/tags_controller.rb
  l.store :tag_copied,                            "%s successfully copied to %s"
  l.store :tag_replace,                           "Tag %s already exists. This copy will completely replace it with a copy of %s."
  l.store :tag_renamed,                           "Tag Renamed"
  l.store :tag_merged,                            "%s merged with %s"
  l.store :tag_not_found,                         "%s and no tag %s"
  l.store :tag_id_not_found,                      "Tag with id %s not found"

  # app/helpers/about_helper.rb
  l.store :classifier_info,                       "Using classifier version %s at build %s."
  l.store :classifier_info_not_found,             "The classifer could not be contacted."

  # app/helpers/application_helper.rb
  l.store :close_flash_tooltip,                   "Close Message"
  l.store :multiple_unread_messages,              "You have multiple messages, see the <a href='%s'>log</a>" 
  l.store :default_search_placeholder,            "Search..."
  l.store :create_feed,                           "Create Feed: '%s'"
  l.store :create_tag,                            "Create Tag: '%s'"
  l.store :public_tag_tooltip,                    "from %s"
  l.store :feed_items_count_tooltip, :singular => "%d item in this feed",
                                     :plural   => "%d items in this feed"

  # app/helpers/bais_slider_helper.rb
  l.store :slider_handle_tooltip,                 "Drag to set the sensitvity of the classifier."
  l.store :first_slider_marker,                   "Very Negative"
  l.store :second_slider_marker,                  "Neutral"
  l.store :third_slider_marker,                   "Slightly Positive"
  l.store :fourth_slider_marker,                  "Strongly Positive"
  l.store :fifth_slider_marker,                   "Very Strongly Positive"

  # app/helpers/collection_job_results_helper.rb
  l.store :collection_failed,                     "Collection Job for %s failed with result: %s"
  l.store :collection_finished,                   "We have finished fetching new items for %s"

  # app/helpers/feed_items_helper.rb
  l.store :positive_training_control,             "Make Positive"
  l.store :negative_training_control,             "Make Negative"
  l.store :remove_training_control,               "Remove Training"
  l.store :start_classifier_button,               "Auto-tag"
  l.store :stop_classifier_button,                "Stop"
  l.store :classifier_progress,                   "Classify changed tags"
  l.store :feed_item_no_title,                    "(no title)"
  
  # app/mailers/notifier.rb
  l.store :subject_prefix,                        "[WINNOW]"
  l.store :deployed_subject,                      "[DEPLOYMENT] r%s deployed"
  l.store :invite_requested_subject,              "Invite Requested"

  # app/mailers/notifier.rb
  l.store :reminder_subject,                      "Password Reminder"
  
  # app/models/collection_job_result.rb
  l.store :unknown_feed,                          "Unknown Feed"

  # app/models/invite.rb
  l.store :default_invite_accepted_subject,       "Invite Accepted"
  l.store :default_invite_accepted_body,          "You request for an invitation to Winnow has been accepted!"
  
  # app/views/about/index.html.erb
  l.store :winnow_info,                           "This is build %s of Winnow."
  
  # app/views/account/activate.html.erb
  l.store :activation_code_label,                 "Activation Code"
  l.store :activate_submit_button,                "Activate"
  
  # app/views/account/edit.html.erb
  l.store :edit_profile_header,                   "Account Details"
  l.store :login_label,                           "Login"
  l.store :password_label,                        "Password"
  l.store :password_confirmation_label,           "Password Confirmation"
  l.store :email_label,                           "Email"
  l.store :firstname_label,                       "First Name"
  l.store :lastname_label,                        "Last Name"
  l.store :time_zone_label,                       "Time Zone"
  l.store :edit_profile_submit_button,            "Save"

  # app/views/account/login.html.erb
  l.store :login_header,                          "Login"
  l.store :remember_me_label,                     "Remember Me"
  l.store :forgot_password_link,                  "Forgot your password?"
  l.store :login_submit_button,                   "Login"
  l.store :reminder_header,                       "Password Reminder"
  l.store :login_link,                            "Back to login"
  l.store :reminder_submit_button,                "Submit"
  l.store :signup_submit_button,                  "Signup"
  l.store :invite_header,                         "Request Invitation"
  l.store :questions_header,                      "Questions"
  l.store :questions_description,                 "optional, answers may encourage a response"
  l.store :hear_question,                         "How did you hear about Winnow?"
  l.store :use_question,                          "How/why do you want to use Winnow?"
  l.store :invite_submit_button,                  "Request Invitation"
  l.store :welcome_header,                        "Welcome to Winnow"
  l.store :welcome_text,                          %|
    <p>
      Winnow is the demonstration environment for the auto-tagging classifier built by <a href="http://www.peerworks.org">Peerworks</a>.
    </p>
    <p>
      This version of Winnow is only tested in the  <a href="http://www.getfirefox.com" target="_blank">Firefox</a> Web Browser, 
      as such things may not work correctly in other browsers.
    </p>
  |

  # app/views/admin/help.html.erb
  l.store :content_label,                         "Content"
  l.store :save_button,                           "Save"
  
  # app/views/admin/info.html.erb
  l.store :textile_reference,                     "Accepts <a href='http://www.textism.com/tools/textile/index.php'>textile</a> formatting"
  
  # app/views/admin/index.html.erb
  l.store :manage_users_link,                     "User Management"
  l.store :manage_users_description,              "View and manage users of winnow."
  l.store :manage_invites_link,                   "Invites"
  l.store :manage_invites_description,            "View and manage invites."
  l.store :manage_item_protection_link,           "Item Protection Management"
  l.store :manage_item_protection_description,    "View and manage the Item Protection."
  l.store :manage_messages_link,                  "Messages"
  l.store :manage_messages_description,           "View and manage messages."
  l.store :manage_info_link,                      "Winnow Info"
  l.store :manage_info_description,               "View and manage the winnow info content."
  l.store :manage_help_link,                      "Help Links"
  l.store :manage_help_description,               "View and manage the help links in winnow."

  # app/views/feed_items/_description.html.erb
  l.store :feed_item_feed_metadata,               "from %s"
  l.store :feed_item_metadata,                    "from %s by %s"
  
  # app/views/feed_items/_feed_item.html.erb
  l.store :add_tag_link,                          "Add Tag"
  
  # app/views/feed_items/_filter_controls.html.erb
  l.store :show_label,                            "Show:"
  l.store :show_all_label,                        "All"
  l.store :show_unread_label,                     "Unread"
  l.store :show_moderated_label,                  "Moderated"
  l.store :sort_label,                            "Sort:"
  l.store :sort_date_label,                       "Date"
  l.store :sort_strength_label,                   "Strength"
  l.store :sidebar_tags_header,                   "Tags"
  l.store :sidebar_add_tag_link,                  "Add"
  l.store :sidebar_cancel_add_tag_link,           "cancel"
  l.store :sidebar_feeds_header,                  "Feeds"
  l.store :sidebar_add_feed_link,                 "Add"
  l.store :sidebar_cancel_add_feed_link,          "cancel"
  l.store :sidebar_folders_header,                "My Folders"
  l.store :sidebar_add_folder_link,               "Add"
  l.store :sidebar_cancel_add_folder_link,        "cancel"
  l.store :feed_for_selected_filters_link,        "Feed with selected filters"
  
  # app/views/feed_items/_info.html.erb
  l.store :confirm_destroy_folder,                "Are you sure?"
  
  # app/views/feed_items/_info.html.erb
  l.store :info_header,                           "Classifier Taggings"
  l.store :info_description,                      %|
    This section shows how your current classifier will classify this item. Tags with 
	  <span style="color:red">red</span> text have also been applied by you on the item.
	|

  # app/views/feed_items/_moderation_panel.html.erb
  l.store :add_tag_button,                        "Add Tag"
  l.store :cancel_add_tag_link,                   "cancel"


  # app/views/feed_items/_text_filter_controls.html.erb
  l.store :feed_items_search_placeholder,         "Search Items..."
  l.store :search_term_too_short,                 "Search requires a word with at least 4 characters"

  # app/views/feed_items/index.html.erb
  l.store :no_script_message,                     "Winnow requires Javascript to be enabled. Please enable Javascript in your browser and refresh."
  
  # app/views/feeds
  # app/views/invites
  # app/views/item_protection
  # app/views/layouts
  # app/views/messages
  # app/views/notifier
  # app/views/taggings
  # app/views/tags
  # app/views/user_notifier
  # app/views/users
  # ActiveRecord validation messages
  # Javascript
  # Icons + tooltips
end
