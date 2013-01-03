[![Build Status](https://secure.travis-ci.org/wr0ngway/lumber.png)](http://travis-ci.org/wr0ngway/lumber)

Lumber
======

Lumber tries to make it easy to use the more robust [log4r](http://log4r.sourceforge.net/) logging system within your rails application.
To do this it sets up log4r configuration from a yml file, and provides utility methods for adding a
:logger accessor to classes dynamically as they get created.  In the default setup shown below, calls
to logger from a model/controller/mailer, will include that classes name in the log output.

To use it in a rails project:

 * add lumber to your Gemfile
 * bundle install
 * run the lumber generator, rails generate lumber, to get a basic config/log4r.yml
 * enable lumber in your rails project

To enable lumber in your rails project, add to your config/application.rb:

    # To expose custom variables in log4r.yml
    # config.lumber.some_option = "some_value
    # you can set default_log_level here, config/environments/*.rb or in config/log4r.yml 
    # config.log_level = :debug
    # enabling lumber sets config.logger to Log4r::Logger['rails']
    config.lumber.enabled = true

You should be able to use lumber in a non-rails project too, but you will have to manually call Lumber.init - see the [docs](http://rubydoc.info/github/wr0ngway/lumber/Lumber#init-class_method) for details on parameters:

    # before Rails::Initializer.run
    #
    require 'lumber'
    Lumber.init(:root => "/my/project", :env => "development")
  
    # Setup parent loggers for some known rails Base classes.  Classes that inherit
    # from these will have their logger as a parent so you can configure logging for
    # subtrees of classes in log4r.yml
    Lumber.setup_logger_hierarchy("ActiveRecord::Base", "rails::models")
    Lumber.setup_logger_hierarchy("ActionController::Base", "rails::controllers")
    Lumber.setup_logger_hierarchy("ActionMailer::Base", "rails::mailers")
  
    # If you really want, you can make all classes have a logger
    # Lumber.setup_logger_hierarchy("Object", "root::object")

Additionally, you can also add loggers to individual classes by including the LumberLoggerSupport module

    class Foo
      include Lumber::LoggerSupport
    end

and Foo.logger/Foo.new.logger will log to a logger named "rails::Foo".  This creates a heirarchy of loggers for classes
nested within modules, so you can use the namespace to enable/disable loggers

If you want to change the log level for a different environment, you can do so in log4r.yml or by using the standard rails "config.log_level" setting in config/environments/<env>.rb

    # Set info as the default log level for production
    config.log_level = :info

Lumber also comes with a Sinatra UI for dynamically overriding log levels at runtime.  To use it, just run Lumber::Server as a rack application.  The easiest way to do this is to map it to a route in your rails routes.rb (make sure you password protect it):

    require 'lumber/server'
    mount Lumber::Server, :at => "/lumber"

This will allow you to temporarily set lower log levels for specific loggers - e.g. if you want a specific model to have DEBUG logging for the next hour. Note that this behavior is enabled by a monitor thread running in your process, so if you want to be able to change the log levels for forked subprocesses (resque, passenger, unicorn, etc), you'll need to restart that thread in an after fork hook by calling Lumber::LevelUtil.start_monitor or use Lumber::LevelUtil.activate_levels for a oneoff activation without the thread.


Copyright
---------

Copyright (c) 2009-2012 Matt Conway. See LICENSE for details.
