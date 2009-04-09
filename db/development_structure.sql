CREATE TABLE `comments` (
  `id` int(11) NOT NULL auto_increment,
  `tag_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `body` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=latin1;

CREATE TABLE `deleted_taggings` (
  `id` int(11) NOT NULL auto_increment,
  `feed_item_id` int(11) NOT NULL,
  `created_on` datetime default NULL,
  `tag_id` int(11) NOT NULL,
  `strength` float NOT NULL default '1',
  `deleted_at` datetime default NULL,
  `user_id` int(11) NOT NULL,
  `classifier_tagging` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `index_taggings_on_deleted_at` (`deleted_at`),
  KEY `index_taggings_on_taggable_id` (`feed_item_id`),
  KEY `index_taggings_on_tag_id` (`tag_id`),
  KEY `dt_user` (`user_id`),
  CONSTRAINT `dt_tag` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`) ON DELETE CASCADE,
  CONSTRAINT `dt_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=113537 DEFAULT CHARSET=latin1;

CREATE TABLE `feed_exclusions` (
  `id` int(11) NOT NULL auto_increment,
  `feed_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=latin1;

CREATE TABLE `feed_item_contents` (
  `feed_item_id` int(11) NOT NULL default '0',
  `content` text,
  PRIMARY KEY  (`feed_item_id`),
  CONSTRAINT `feed_item_contents_ibfk_1` FOREIGN KEY (`feed_item_id`) REFERENCES `feed_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `feed_item_text_indices` (
  `feed_item_id` int(11) NOT NULL auto_increment,
  `content` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`feed_item_id`),
  FULLTEXT KEY `feed_items_full_text_index` (`content`)
) ENGINE=MyISAM AUTO_INCREMENT=2716187 DEFAULT CHARSET=latin1;

CREATE TABLE `feed_items` (
  `id` int(11) NOT NULL auto_increment,
  `feed_id` int(11) default NULL,
  `updated` datetime default NULL,
  `created_on` datetime default NULL,
  `link` varchar(255) default NULL,
  `title` varchar(255) default NULL,
  `author` varchar(255) default NULL,
  `collector_link` varchar(255) default NULL,
  `uri` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `index_feed_items_on_uri` (`uri`),
  UNIQUE KEY `index_feed_items_on_link` (`link`),
  KEY `index_feed_items_on_time` (`updated`),
  KEY `index_feed_items_on_feed_id` (`feed_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2716187 DEFAULT CHARSET=latin1;

CREATE TABLE `feed_subscriptions` (
  `id` int(11) NOT NULL auto_increment,
  `feed_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `created_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `index_feed_subscriptions_on_feed_id_and_user_id` (`feed_id`,`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1790 DEFAULT CHARSET=latin1;

CREATE TABLE `feedbacks` (
  `id` int(11) NOT NULL auto_increment,
  `body` text,
  `user_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;

CREATE TABLE `feeds` (
  `id` int(11) NOT NULL auto_increment,
  `via` varchar(255) default NULL,
  `title` varchar(255) default NULL,
  `alternate` varchar(255) default NULL,
  `updated_on` datetime default NULL,
  `created_on` datetime default NULL,
  `feed_items_count` int(11) default '0',
  `duplicate_id` int(11) default NULL,
  `collector_link` varchar(255) default NULL,
  `updated` datetime default NULL,
  `uri` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `index_feeds_on_uri` (`uri`),
  KEY `index_feeds_on_title` (`title`),
  KEY `index_feeds_on_link` (`alternate`)
) ENGINE=InnoDB AUTO_INCREMENT=3925 DEFAULT CHARSET=latin1;

CREATE TABLE `feeds_folders` (
  `folder_id` int(11) default NULL,
  `feed_id` int(11) default NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `folders` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `user_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `position` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=latin1;

CREATE TABLE `folders_tags` (
  `folder_id` int(11) default NULL,
  `tag_id` int(11) default NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `invites` (
  `id` int(11) NOT NULL auto_increment,
  `email` varchar(255) default NULL,
  `code` varchar(255) default NULL,
  `user_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `hear` text,
  `use` text,
  `subject` varchar(255) default NULL,
  `body` text,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=latin1;

CREATE TABLE `message_readings` (
  `id` int(11) NOT NULL auto_increment,
  `message_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1353 DEFAULT CHARSET=latin1;

CREATE TABLE `messages` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `body` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1282 DEFAULT CHARSET=latin1;

CREATE TABLE `read_items` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `feed_item_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `index_read_items_on_user_id_and_feed_item_id` (`user_id`,`feed_item_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1261838 DEFAULT CHARSET=latin1;

CREATE TABLE `readings` (
  `id` int(11) NOT NULL auto_increment,
  `readable_type` varchar(255) default NULL,
  `readable_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `index_readings_on_user_id_and_readable_id_and_readable_type` (`user_id`,`readable_id`,`readable_type`)
) ENGINE=InnoDB AUTO_INCREMENT=1253000 DEFAULT CHARSET=utf8;

CREATE TABLE `roles` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(40) default NULL,
  `authorizable_type` varchar(30) default NULL,
  `authorizable_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=81 DEFAULT CHARSET=latin1;

CREATE TABLE `roles_users` (
  `user_id` int(11) default NULL,
  `role_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `settings` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `value` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

CREATE TABLE `tag_exclusions` (
  `id` int(11) NOT NULL auto_increment,
  `tag_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=latin1;

CREATE TABLE `tag_subscriptions` (
  `id` int(11) NOT NULL auto_increment,
  `tag_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `created_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `index_tag_subscriptions_on_tag_id_and_user_id` (`tag_id`,`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=337 DEFAULT CHARSET=latin1;

CREATE TABLE `tag_usages` (
  `id` int(11) NOT NULL auto_increment,
  `tag_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `ip_address` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=614 DEFAULT CHARSET=utf8;

CREATE TABLE `taggings` (
  `id` int(11) NOT NULL auto_increment,
  `feed_item_id` int(11) NOT NULL,
  `created_on` datetime default NULL,
  `tag_id` int(11) NOT NULL,
  `strength` float NOT NULL default '1',
  `user_id` int(11) NOT NULL,
  `classifier_tagging` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `index_taggings_on_feed_item_id_and_tag_id_and_classifier_tagging` (`feed_item_id`,`tag_id`,`classifier_tagging`),
  KEY `index_taggings_on_tag_id_and_classifier_tagging_and_strength` (`tag_id`,`classifier_tagging`,`strength`),
  CONSTRAINT `taggings_feed_item` FOREIGN KEY (`feed_item_id`) REFERENCES `feed_items` (`id`),
  CONSTRAINT `taggings_ibfk_1` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3916530 DEFAULT CHARSET=latin1;

CREATE TABLE `tags` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) character set latin1 collate latin1_general_cs default NULL,
  `user_id` int(11) NOT NULL,
  `public` tinyint(1) default NULL,
  `description` text,
  `bias` float default '1.2',
  `created_on` datetime default NULL,
  `updated_on` datetime default NULL,
  `last_classified_at` datetime default NULL,
  `show_in_sidebar` tinyint(1) default '1',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `index_tags_on_user_id_and_name` (`user_id`,`name`)
) ENGINE=InnoDB AUTO_INCREMENT=314 DEFAULT CHARSET=latin1;

CREATE TABLE `users` (
  `id` int(11) NOT NULL auto_increment,
  `login` varchar(80) NOT NULL default '',
  `crypted_password` varchar(255) default NULL,
  `email` varchar(60) NOT NULL default '',
  `firstname` varchar(40) default NULL,
  `lastname` varchar(40) default NULL,
  `activation_code` varchar(40) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `logged_in_at` datetime default NULL,
  `deleted_at` datetime default NULL,
  `activated_at` datetime default NULL,
  `remember_token` varchar(255) default NULL,
  `remember_token_expires_at` datetime default NULL,
  `last_accessed_at` datetime default NULL,
  `time_zone` varchar(255) default 'UTC',
  `reminder_code` varchar(255) default NULL,
  `reminder_expires_at` datetime default NULL,
  `prototype` tinyint(1) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=latin1;

INSERT INTO schema_migrations (version) VALUES ('1');

INSERT INTO schema_migrations (version) VALUES ('10');

INSERT INTO schema_migrations (version) VALUES ('100');

INSERT INTO schema_migrations (version) VALUES ('101');

INSERT INTO schema_migrations (version) VALUES ('102');

INSERT INTO schema_migrations (version) VALUES ('103');

INSERT INTO schema_migrations (version) VALUES ('104');

INSERT INTO schema_migrations (version) VALUES ('105');

INSERT INTO schema_migrations (version) VALUES ('106');

INSERT INTO schema_migrations (version) VALUES ('107');

INSERT INTO schema_migrations (version) VALUES ('108');

INSERT INTO schema_migrations (version) VALUES ('109');

INSERT INTO schema_migrations (version) VALUES ('11');

INSERT INTO schema_migrations (version) VALUES ('110');

INSERT INTO schema_migrations (version) VALUES ('111');

INSERT INTO schema_migrations (version) VALUES ('112');

INSERT INTO schema_migrations (version) VALUES ('113');

INSERT INTO schema_migrations (version) VALUES ('114');

INSERT INTO schema_migrations (version) VALUES ('115');

INSERT INTO schema_migrations (version) VALUES ('116');

INSERT INTO schema_migrations (version) VALUES ('117');

INSERT INTO schema_migrations (version) VALUES ('118');

INSERT INTO schema_migrations (version) VALUES ('119');

INSERT INTO schema_migrations (version) VALUES ('12');

INSERT INTO schema_migrations (version) VALUES ('120');

INSERT INTO schema_migrations (version) VALUES ('121');

INSERT INTO schema_migrations (version) VALUES ('122');

INSERT INTO schema_migrations (version) VALUES ('123');

INSERT INTO schema_migrations (version) VALUES ('124');

INSERT INTO schema_migrations (version) VALUES ('125');

INSERT INTO schema_migrations (version) VALUES ('126');

INSERT INTO schema_migrations (version) VALUES ('127');

INSERT INTO schema_migrations (version) VALUES ('128');

INSERT INTO schema_migrations (version) VALUES ('129');

INSERT INTO schema_migrations (version) VALUES ('13');

INSERT INTO schema_migrations (version) VALUES ('130');

INSERT INTO schema_migrations (version) VALUES ('131');

INSERT INTO schema_migrations (version) VALUES ('132');

INSERT INTO schema_migrations (version) VALUES ('133');

INSERT INTO schema_migrations (version) VALUES ('134');

INSERT INTO schema_migrations (version) VALUES ('135');

INSERT INTO schema_migrations (version) VALUES ('136');

INSERT INTO schema_migrations (version) VALUES ('137');

INSERT INTO schema_migrations (version) VALUES ('138');

INSERT INTO schema_migrations (version) VALUES ('139');

INSERT INTO schema_migrations (version) VALUES ('14');

INSERT INTO schema_migrations (version) VALUES ('140');

INSERT INTO schema_migrations (version) VALUES ('141');

INSERT INTO schema_migrations (version) VALUES ('15');

INSERT INTO schema_migrations (version) VALUES ('16');

INSERT INTO schema_migrations (version) VALUES ('17');

INSERT INTO schema_migrations (version) VALUES ('18');

INSERT INTO schema_migrations (version) VALUES ('19');

INSERT INTO schema_migrations (version) VALUES ('2');

INSERT INTO schema_migrations (version) VALUES ('20');

INSERT INTO schema_migrations (version) VALUES ('20080821201921');

INSERT INTO schema_migrations (version) VALUES ('20080827125956');

INSERT INTO schema_migrations (version) VALUES ('20080828010731');

INSERT INTO schema_migrations (version) VALUES ('20080904034859');

INSERT INTO schema_migrations (version) VALUES ('20081205045828');

INSERT INTO schema_migrations (version) VALUES ('20081205050044');

INSERT INTO schema_migrations (version) VALUES ('20081205050334');

INSERT INTO schema_migrations (version) VALUES ('20081205054256');

INSERT INTO schema_migrations (version) VALUES ('20081205054648');

INSERT INTO schema_migrations (version) VALUES ('20081209224416');

INSERT INTO schema_migrations (version) VALUES ('20081209224809');

INSERT INTO schema_migrations (version) VALUES ('20081209224938');

INSERT INTO schema_migrations (version) VALUES ('20081210173353');

INSERT INTO schema_migrations (version) VALUES ('20081216160830');

INSERT INTO schema_migrations (version) VALUES ('20081218171321');

INSERT INTO schema_migrations (version) VALUES ('20081218171514');

INSERT INTO schema_migrations (version) VALUES ('20081219163051');

INSERT INTO schema_migrations (version) VALUES ('20081219164505');

INSERT INTO schema_migrations (version) VALUES ('20081219165403');

INSERT INTO schema_migrations (version) VALUES ('20090113171837');

INSERT INTO schema_migrations (version) VALUES ('20090325182226');

INSERT INTO schema_migrations (version) VALUES ('20090327060429');

INSERT INTO schema_migrations (version) VALUES ('20090409011826');

INSERT INTO schema_migrations (version) VALUES ('21');

INSERT INTO schema_migrations (version) VALUES ('22');

INSERT INTO schema_migrations (version) VALUES ('23');

INSERT INTO schema_migrations (version) VALUES ('24');

INSERT INTO schema_migrations (version) VALUES ('25');

INSERT INTO schema_migrations (version) VALUES ('26');

INSERT INTO schema_migrations (version) VALUES ('27');

INSERT INTO schema_migrations (version) VALUES ('28');

INSERT INTO schema_migrations (version) VALUES ('29');

INSERT INTO schema_migrations (version) VALUES ('3');

INSERT INTO schema_migrations (version) VALUES ('30');

INSERT INTO schema_migrations (version) VALUES ('31');

INSERT INTO schema_migrations (version) VALUES ('32');

INSERT INTO schema_migrations (version) VALUES ('33');

INSERT INTO schema_migrations (version) VALUES ('34');

INSERT INTO schema_migrations (version) VALUES ('35');

INSERT INTO schema_migrations (version) VALUES ('36');

INSERT INTO schema_migrations (version) VALUES ('37');

INSERT INTO schema_migrations (version) VALUES ('38');

INSERT INTO schema_migrations (version) VALUES ('39');

INSERT INTO schema_migrations (version) VALUES ('4');

INSERT INTO schema_migrations (version) VALUES ('40');

INSERT INTO schema_migrations (version) VALUES ('41');

INSERT INTO schema_migrations (version) VALUES ('42');

INSERT INTO schema_migrations (version) VALUES ('43');

INSERT INTO schema_migrations (version) VALUES ('44');

INSERT INTO schema_migrations (version) VALUES ('45');

INSERT INTO schema_migrations (version) VALUES ('46');

INSERT INTO schema_migrations (version) VALUES ('47');

INSERT INTO schema_migrations (version) VALUES ('48');

INSERT INTO schema_migrations (version) VALUES ('49');

INSERT INTO schema_migrations (version) VALUES ('5');

INSERT INTO schema_migrations (version) VALUES ('50');

INSERT INTO schema_migrations (version) VALUES ('51');

INSERT INTO schema_migrations (version) VALUES ('52');

INSERT INTO schema_migrations (version) VALUES ('53');

INSERT INTO schema_migrations (version) VALUES ('54');

INSERT INTO schema_migrations (version) VALUES ('55');

INSERT INTO schema_migrations (version) VALUES ('56');

INSERT INTO schema_migrations (version) VALUES ('57');

INSERT INTO schema_migrations (version) VALUES ('58');

INSERT INTO schema_migrations (version) VALUES ('59');

INSERT INTO schema_migrations (version) VALUES ('6');

INSERT INTO schema_migrations (version) VALUES ('60');

INSERT INTO schema_migrations (version) VALUES ('61');

INSERT INTO schema_migrations (version) VALUES ('62');

INSERT INTO schema_migrations (version) VALUES ('63');

INSERT INTO schema_migrations (version) VALUES ('64');

INSERT INTO schema_migrations (version) VALUES ('65');

INSERT INTO schema_migrations (version) VALUES ('66');

INSERT INTO schema_migrations (version) VALUES ('67');

INSERT INTO schema_migrations (version) VALUES ('68');

INSERT INTO schema_migrations (version) VALUES ('69');

INSERT INTO schema_migrations (version) VALUES ('7');

INSERT INTO schema_migrations (version) VALUES ('70');

INSERT INTO schema_migrations (version) VALUES ('71');

INSERT INTO schema_migrations (version) VALUES ('72');

INSERT INTO schema_migrations (version) VALUES ('73');

INSERT INTO schema_migrations (version) VALUES ('74');

INSERT INTO schema_migrations (version) VALUES ('75');

INSERT INTO schema_migrations (version) VALUES ('76');

INSERT INTO schema_migrations (version) VALUES ('77');

INSERT INTO schema_migrations (version) VALUES ('78');

INSERT INTO schema_migrations (version) VALUES ('79');

INSERT INTO schema_migrations (version) VALUES ('8');

INSERT INTO schema_migrations (version) VALUES ('81');

INSERT INTO schema_migrations (version) VALUES ('82');

INSERT INTO schema_migrations (version) VALUES ('83');

INSERT INTO schema_migrations (version) VALUES ('84');

INSERT INTO schema_migrations (version) VALUES ('85');

INSERT INTO schema_migrations (version) VALUES ('86');

INSERT INTO schema_migrations (version) VALUES ('87');

INSERT INTO schema_migrations (version) VALUES ('88');

INSERT INTO schema_migrations (version) VALUES ('89');

INSERT INTO schema_migrations (version) VALUES ('9');

INSERT INTO schema_migrations (version) VALUES ('90');

INSERT INTO schema_migrations (version) VALUES ('91');

INSERT INTO schema_migrations (version) VALUES ('92');

INSERT INTO schema_migrations (version) VALUES ('93');

INSERT INTO schema_migrations (version) VALUES ('94');

INSERT INTO schema_migrations (version) VALUES ('95');

INSERT INTO schema_migrations (version) VALUES ('96');

INSERT INTO schema_migrations (version) VALUES ('97');

INSERT INTO schema_migrations (version) VALUES ('98');

INSERT INTO schema_migrations (version) VALUES ('99');