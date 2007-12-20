ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS.update(:database_manager => SqlSessionStore)
SqlSessionStore.session_class = MysqlSession
