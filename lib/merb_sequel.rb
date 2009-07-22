if defined?(Merb::Plugins)
  Merb::Plugins.config[:merb_sequel] = {}
  require File.join(File.dirname(__FILE__) / "sequel_ext" / "model")
  require File.join(File.dirname(__FILE__) / "merb" / "orms" / "sequel" / "connection")
  Merb::Plugins.add_rakefiles "merb_sequel" / "merbtasks"
  
  Sequel::Model.send(:include, Merb::Orms::Sequel::ModelExtensions)

  # Connects to the database and handles session
  #
  # Connects to the database and loads sequel sessions if we use them.
  # Sets router to identify models using Model.pk.
  class Merb::Orms::Sequel::Connect < Merb::BootLoader
    after BeforeAppLoads

    def self.run
      Merb::Orms::Sequel.connect
      if Merb::Config.session_stores.include?(:sequel)
        Merb.logger.debug "Using Sequel sessions"
        require File.join(File.dirname(__FILE__) / "merb" / "session" / "sequel_session")
      end
      
      Merb::Router.root_behavior = Merb::Router.root_behavior.identify(Sequel::Model => :pk)
    end

  end
  
  # Disconnects from DB before starting reloading classes
  #
  # There is a problem with the pg gem driver wich causes infinite loop
  # duing reloading process.
  #
  # Disconnect only when fork_for_class_relaod is set and we're not in
  # testing mode.
  class Merb::BootLoader::DisconnectBeforeStartTransaction < Merb::BootLoader
    before LoadClasses

    def self.run
      if Merb::Config[:fork_for_class_load] && !Merb.testing?
        Merb.logger.debug "Disconnecting database connection before starting transaction."
        ::Sequel::DATABASES.each { |db| db.disconnect }
      end
    end
  end
  
  # Load generators
  generators = File.join(File.dirname(__FILE__), 'generators')
  Merb.add_generators generators / :migration
  Merb.add_generators generators / :model
  Merb.add_generators generators / :resource_controller
  Merb.add_generators generators / :session_migration
end
