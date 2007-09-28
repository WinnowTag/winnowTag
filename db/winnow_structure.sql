-- phpMyAdmin SQL Dump
-- version 2.6.1-pl3
-- http://www.phpmyadmin.net
-- 
-- Host: nowwin-development.mariposan.com
-- Generation Time: Sep 22, 2005 at 06:24 PM
-- Server version: 4.1.13
-- PHP Version: 4.3.10
-- 
-- Database: `nowwin_development`
-- 

-- --------------------------------------------------------

-- 
-- Table structure for table `feeds`
-- 

DROP TABLE IF EXISTS `feeds`;
CREATE TABLE IF NOT EXISTS `feeds` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `url` varchar(255) default NULL,
  `title` varchar(255) default NULL,
  `link` varchar(255) default NULL,
  `xml_data` longtext,
  `http_headers` text,
  `last_retrieved` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=451 ;

-- --------------------------------------------------------

-- 
-- Table structure for table `seed_items`
-- 

DROP TABLE IF EXISTS `seed_items`;
CREATE TABLE IF NOT EXISTS `seed_items` (
  `id` int(11) NOT NULL auto_increment,
  `seed_id` int(11) NOT NULL default '0',
  `xml_data` longtext NOT NULL,
  `title` varchar(255) NOT NULL default '',
  `time` datetime default NULL,
  `time_retrieved` datetime default NULL,
  `unique_id` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`),
  KEY `fk_items_seed` (`seed_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=3363 ;

-- --------------------------------------------------------

-- 
-- Table structure for table `seeds`
-- 

DROP TABLE IF EXISTS `seeds`;
CREATE TABLE IF NOT EXISTS `seeds` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `url` varchar(255) default NULL,
  `title` varchar(255) default NULL,
  `time_last_retrieved` datetime default NULL,
  `last_xml_data` longtext,
  `last_http_headers` text,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=30 ;
        