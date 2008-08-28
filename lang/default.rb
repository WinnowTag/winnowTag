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

  # app/controllers/collection_job_results_controller.rb
  l.store :collection_failed,                     "Collection Job for %s failed with result: %s"

  # app/controllers/feed_items_controller.rb
  l.store :could_not_load_clues,                  "Could not load the clues, please try again later."
  
  # app/controllers/feeds_controller.rb
  l.store :feed_added,                            "Thanks for adding the feed from %s. We will fetch the items soon. The feed has also been added to your feeds folder in the sidebar."
  l.store :feed_existed,                          "We already have the feed from %s, however we will update it now. The feed has also been added to your feeds folder in the sidebar."
  l.store :feeds_imported,           :singular => "Imported %d feed from your OPML file",
                                     :plural   => "Imported %d feeds from your OPML file"

  # app/controllers/messages_controller.rb
  l.store :message_created,                       "Message was successfully created"
  l.store :message_updated,                       "Message was successfully updated"

  # app/controllers/taggings_controller.rb
  l.store :bad_method,                            "Bad Request. Should be POST. Please report this bug. Make sure you have Javascript enabled too!"
  l.store :bad_params,                            "Bad Request. Missing Parameters. Please report this bug. Make sure you have Javascript enabled too!"

  # app/controllers/tags_controller.rb
  l.store :tag_copied,                            "%s successfully copied to %s"
  l.store :tag_replace,                           "Tag %s already exists. This copy will completely replace it with a copy of %s."
  l.store :tag_merged,                            "%s merged with %s"
  l.store :tag_not_found,                         "%s and no tag %s"
  l.store :tag_id_not_found,                      "Tag with id %s not found"

  # app/helpers/about_helper.rb
  l.store :classifier_info,                       "Using classifier version %s at build %s."
  l.store :classifier_info_not_found,             "The classifer could not be contacted."

  # app/helpers/application_helper.rb
  l.store :default_search_placeholder,            "Search..."
  l.store :create_feed,                           "Create Feed: '%s'"
  l.store :create_tag,                            "Create Tag: '%s'"
  l.store :public_tag_tooltip,                    "from %s"

  # app/helpers/bais_slider_helper.rb
  l.store :slider_handle_tooltip,                 "Drag to set the sensitvity of the classifier."
  l.store :first_slider_marker,                   "Very Negative"
  l.store :second_slider_marker,                  "Neutral"
  l.store :third_slider_marker,                   "Slightly Positive"
  l.store :fourth_slider_marker,                  "Strongly Positive"
  l.store :fifth_slider_marker,                   "Very Strongly Positive"

  # app/helpers/feed_items_helper.rb
  l.store :automatic_label,                       "Automatic"
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
  
  # app/models/invite.rb
  l.store :default_invite_accepted_subject,       "Invite Accepted"
  l.store :default_invite_accepted_body,          "You request for an invitation to Winnow has been accepted!"
  
  # app/views/about/index.html.erb
  l.store :winnow_revision,                       "This is build %s of Winnow."
  
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
  l.store :manage_messages_link,                  "Messages"
  l.store :manage_messages_description,           "View and manage messages."
  l.store :manage_info_link,                      "Winnow Info"
  l.store :manage_info_description,               "View and manage the winnow info content."
  l.store :manage_help_link,                      "Help Links"
  l.store :manage_help_description,               "View and manage the help links in winnow."
  l.store :manage_feedback_link,                  "Feedback"
  l.store :manage_feedback_description,           "View feedback left by the users of winnow."

  # app/views/feed_items/_description.html.erb
  l.store :feed_item_feed_metadata,               "from %s"
  l.store :feed_item_metadata,                    "from %s by %s"
  
  # app/views/feed_items/_feed_item.html.erb
  l.store :add_tag_link,                          "Add Tag"
  l.store :open_original_feed_item,               "Go to original item"
  
  # app/views/feed_items/_filter_controls.html.erb
  l.store :show_label,                            "Show"
  l.store :show_all_label,                        "All"
  l.store :show_unread_label,                     "Unread"
  l.store :show_trained_label,                    "Trained"
  l.store :sort_label,                            "Sort"
  l.store :sort_date_label,                       "Date"
  l.store :sort_strength_label,                   "Strength"
  l.store :sidebar_tags_header,                   "Tags"
  l.store :sidebar_add_tag_link,                  "Add Tag"
  l.store :sidebar_cancel_add_tag_link,           "cancel"
  l.store :sidebar_feeds_header,                  "Feeds"
  l.store :sidebar_add_feed_link,                 "Add Feed"
  l.store :sidebar_cancel_add_feed_link,          "cancel"
  l.store :sidebar_folders_header,                "Folders"
  l.store :sidebar_add_folder_link,               "Add Folder"
  l.store :sidebar_cancel_add_folder_link,        "cancel"
  l.store :feed_for_selected_filters,             "Feed"
  l.store :clear_selected_filters,                "Clear"
  
  # app/views/feed_items/_info.html.erb
  l.store :confirm_destroy_folder,                "Are you sure?"
  
  # app/views/feed_items/_moderation_panel.html.erb
  l.store :add_tag_button,                     "Add Tag"


  # app/views/feed_items/_text_filter_controls.html.erb
  l.store :feed_items_search_placeholder,         "Search Items..."
  l.store :search_term_too_short,                 "Search requires a word with at least 4 characters"

  # app/views/feed_items/index.html.erb
  l.store :no_script_message,                     "Winnow requires Javascript to be enabled. Please enable Javascript in your browser and refresh."
  l.store :selected_filters,                      "Selected Filters"
  l.store :previous_item,                         "Previous Item"
  l.store :next_item,                             "Next Item"
  l.store :mark_all_read,                         "Mark All Read"    
  
  # app/views/feedbacks/_feedback.html.erb
  l.store :feedback_metadata,                     "%s on %s"
  
  # app/views/feedbacks/_form.html.erb
  l.store :feedback_submit_button,                  "Submit"
  l.store :feedback_cancel_link,                    "cancel"
  
  # app/views/feedbacks/_header_controls.html.erb
  l.store :feedback_sort_user_label,                "User"
  l.store :feedback_sort_date_label,                "Date"
  l.store :feedback_search_placeholder,             "Search Feedback..."

  # app/views/feeds/_feed.html.erb
  l.store :last_updated,                            "Last Updated"
  l.store :globally_exclude,                        "Globally Exclude"
  l.store :show,                                    "Show"
  
  # app/views/feeds/_header_controls.html.erb
  l.store :feeds_header_add_import,                 "Add / Import"
  l.store :feeds_header_title,                      "Title"
  l.store :feeds_header_globally_exclude,           "Globally Exclude"
  l.store :feeds_header_items,                      "Items"
  l.store :feeds_header_created,                    "Created"
  l.store :feeds_header_last_updated,               "Last Updated"
  l.store :feeds_header_search_placeholder,         "Search Feeds..."
  
  # app/views/feeds/error.html.erb
  l.store :feeds_back_to_feeds,                     "Back to Feeds"

  # app/views/feeds/import.html.erb
  l.store :feeds_add_import,                        "Add / Import Feeds"
  l.store :feeds_new_description,                   "Enter the url of a feed or web page to add to Winnow. Only items with enough text for the classifier to use will be collected from the feed."
  l.store :add_feed_button,                         "Add Feed"
  l.store :feeds_import_description,                "You can upload an OPML file containing a list of feeds. Most feed readers support exporting subscription lists in OPML format so you can easily add your feeds to Winnow."
  l.store :upload,                                  "Upload"
  l.store :feeds_add_to_winnow,                     "Add to Winnow"
  l.store :feeds_new_bookmarklet_description,       "Drag this button to your bookmark bar, then when you find a site you want to add to Winnow, just click the button."
  l.store :feeds_bookmarklet_js_error_message,      "Drag this button to your bookmark or right click and select 'Bookmark This Link'"
  l.store :cancel,                                  "cancel"
  
  # app/views/invites/_form.html.erb
  l.store :invites_activate,                        "Activate?"
  l.store :create,                                  "Create"
  l.store :update,                                  "Update"

  # app/views/invites/header_controls.html.erb
  l.store :created,                                 "Created"
  l.store :email,                                   "Email"
  l.store :status,                                  "Status"
  
  # app/views/invites/_invite.html.erb
  l.store :activate,                                "Activate"
  l.store :edit,                                    "Edit"
  l.store :destroy,                                 "Destroy"
  l.store :are_you_sure,                            "Are you sure?"
  l.store :email_address,                           "Email Address"
  l.store :invites_accepted,                        "Accepted:"
  l.store :invites_activated,                       "Activated:"
  l.store :invites_requested,                       "Requested"
  l.store :invites_question,                        "Question"
  l.store :invites_no_answers,                      "The user did not answer any questions."
  l.store :invites_how_did_you_hear,                "How did you hear about Winnow?"
  l.store :invites_how_do_you_want_to_use_winnow,   "How/why do you want to use Winnow?"
  
  l.store :invites_subject_label,                   "Subject:"
  l.store :invites_body_label,                      "Body:"
  
  # app/views/invites/edit.html.erb
  l.store :invites_edit_invite,                     "Edit Invite"
  
  # app/views/invites/new.html.erb
  l.store :invites_create_invite,                   "Create Invite"
	
  # app/views/layouts/_navbar.html.erb
  l.store :about,                                   "About"
  l.store :profile,                                 "Profile"
  l.store :logout,                                  "Logout"
  l.store :winnow_info,                             "Winnow Info"
  l.store :items,                                   "Items"
  l.store :my_tags,                                 "My Tags"
  l.store :public_tags,                             "Public Tags"
  l.store :feeds,                                   "Feeds"
  l.store :admin,                                   "Admin"
  l.store :help,                                    "Help"
  l.store :leave_feedback,                          "Leave Feedback"

  # app/views/messages/_header_controls.html.erb  
  l.store :messages_create_message,                 "Create Message"

  # app/views/messages/_sidebar.html.erb
  l.store :messages_messages,                       "Messages"
  l.store :messages_empty,                          "You have no recent messages."

  # app/views/messages/edit.html.erb
  l.store :messages_editing_messages,               "Editing message"
  l.store :back,                                    "Back"
  
  # app/views/messages/index.html.erb
  l.store :messages_no_messages_match,              "No messages matched your search criteria."
  
  # app/views/messages/new.html.erb
  l.store :messages_new_message,                    "New message"
  
  # app/views/notifier/deployed.html.erb
  l.store :notifier_deployed_text,               
  %|Hello Peerworks folk,

  Revision %s of "%s" has just be deployed to %s by %s.

  Comment: %s

  Regards,

  Winnow Deployment Notifier|

  # app/views/notifier/invite_requested.html.erb  
  l.store :notifier_invite_requested_text,
  %|%s has submitted an invitation request.

  How did you hear about Winnow?
  %s

  How/why do you want to use Winnow?
  %s|
  
  # app/views/taggings/destroy.js.rjs
  l.store :taggings_destroy_message,                %|You have removed the last example of tag %s, do you want to remove it from your tags page?|
  
  # app/views/tags/_header_controls.html.erb
  l.store :tags_header_name,                        "Name"
  l.store :tags_header_last_trained,                "Last Trained"
  l.store :tags_header_comments,                    "Comments"
  l.store :tags_header_positive,                    "Positive"
  l.store :tags_header_negative,                    "Negative"
  l.store :tags_header_automatic,                   "Automatic"
  l.store :tags_header_state,                       "State"
  l.store :tags_header_search_placeholder,          "Search Tags..."

  # app/views/tags/_public_tag.html.erb
  l.store :tags_last_trained,                       "Last Trained"
  l.store :tags_feed_link,                          "Feed"
  l.store :tags_globally_exclude,                   "Globally Exclude"
  l.store :tags_subscribe,                          "Subscribe"
  l.store :view_all_items,                          "Show items tagged with %s"
  l.store :view_tagged_items,                       "Show items trained with %s"
  l.store :copy,                                    "Copy"
  l.store :tags_copy_link_title,                    "Copy %s"
  l.store :no_comments_for_this_tag,                "There are no comments for this tag."
  l.store :add_a_comment,                           "Add a comment:"

  # app/views/tags/_summary.html.erb
  l.store :positive,                                "Positive"
  l.store :negative,                                "Negative"
  l.store :comments,                                "Comments"  

  # app/views/tags/_subscribed_tag.html.erb
  l.store :tags_public,                             "Public"
  l.store :tags_destroy_link_title,                 "Unsubscribe %s"

  # app/views/tags/_tag.html.erb
  l.store :tags_click_to_edit_tag_text,             "Click to edit tag name"
  l.store :tags_save_text,                          "Save"
  l.store :tags_blank_comment,                      "..."
  l.store :tags_click_to_edit_comment_text,         "Click to edit tag comment"
  l.store :tags_destroy_confirm_text,               "Do you really want to delete %s?\n\nThis can't be undone."
  l.store :tags_editing_tag_name,                   "Editing %s"
  l.store :tags_merge_confirm_text,                 "This will merge %s with %s. Are you sure you want to do this?"
  l.store :tags_sidebar_confirm_message,            %|You have removed the tag %s from your sidebar, do you want to remove it from your tags page?|
  l.store :tags_unsubscribe_text,                   "You have been unsubscribed from the public %s. You can subscribe on the Public Tags page."
  
  # app/views/user_notifier
  l.store :user_notifier_activation_text,           "%s, your account has been activated.  You may now visit winnow at: %s"
  l.store :user_notifier_invite_accepted,           %|%s

Please visit %s to signup for your account.|
  l.store :user_notifier_invite_requested,          "Your request for an invitation to Winnow has been submitted. You will be notified at %s when your invitation is accepted."
  l.store :user_notifier_reminder_text,             "To update your password, visit %s"
  l.store :user_notifier_signup_notification_text,  %|Welcome to Winnow, %s.

Please click on the following link to confirm your registration:

<a href="%s">Click me!</a>

%s|

  # app/views/users/_header_controls.html.erb
  l.store :users_create_user,                       'Create User'
  l.store :users_export,                            'Export (CSV)'
  l.store :users_header_login,                      "Login"
  l.store :users_header_name,                       "Name"
  l.store :users_header_email,                      "Email"
  l.store :users_header_last_logged_in,             "Last Logged In"
  l.store :users_header_last_accessed,              "Last Accessed"
  l.store :users_header_last_trained,               "Last Trained"
  l.store :users_header_number_of_tags,             "Number of Tags"
  l.store :users_search_placeholder,                "Search Users..."
  
  l.store :users_login_confirm,                     %|This will log you in as %s. You will need to log out and login as yourself to use your own account again.
  
Are you sure you want to continue?|
  l.store :users_destroy_confirm,                   "Really delete %s?"
  
  l.store :users_display_name,                      "Display Name"
  l.store :users_last_logged_in,                    "Last Logged In"
  l.store :users_last_accessed,                     "Last Accessed"
  l.store :users_last_trained,                      "Last Trained"
  l.store :users_number_of_tags,                    "Number of Tags"
  l.store :users_save_changes,                      'Save changes'
  
  l.store :users_registered,                        "Registered"
  l.store :users_last_tagged,                       "Last Tagged"
  l.store :users_average_tags_per_item,             "Average Tags per Item"
  l.store :users_percentage_tagged,                 "Percentage Tagged"
  
  # ActiveRecord validation messages
  # Javascript
end
