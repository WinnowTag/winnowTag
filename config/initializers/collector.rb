logger_suffix = RAILS_ENV == 'test' ? 'test' : ""
WINNOW_COLLECT_LOG = File.join(RAILS_ROOT, 'log', "winnow_collect.log#{logger_suffix}")
