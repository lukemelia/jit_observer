$:.unshift(File.dirname(__FILE__ + '.rb') + '/../lib') unless $:.include?(File.dirname(__FILE__ + '.rb') + '/../lib')

require 'singleton'
require 'set'
require 'active_support'
require 'observable_extensions'
require 'jit_observer_registry'
  
class JitObserver
  include Singleton
  
  VERSION = 0.1
  
  class << self
    
    def observe(*observable_names)
      observable_names.flatten!
      observable_names.collect! { |name| name.to_s.camelize }
      define_method(:explicitly_observed_class_names) { Set.new(observable_names)}
    end
    
    def clear_observed_classes
      define_method(:explicitly_observed_class_names) { Set.new() }
    end
    
    def default_observed_class_name
      if observed_class_name = name[/(.*)Observer/, 1]
        observed_class_name
      else
        nil
      end
    end
  end
  
  def initialize
    # Start observing any classes we are interested in that already are defined, as well as their subclasses
    observed_class_names.select{ |o| ActiveSupport::Dependencies.qualified_const_defined?(o) }.each do |observed_class_name|
      klass = observed_class_name.constantize
      add_observer!(klass)
      klass.send(:subclasses).each do |subclass|
        add_observer!(subclass)
      end
    end
    
    JitObserverRegistry.register(self)
  end
  
  def start_observing(klass)
    add_observer!(klass)
  end
  
  def observed_class_names
    if respond_to?(:explicitly_observed_class_names) && !explicitly_observed_class_names.empty?
      explicitly_observed_class_names
    else
      [self.class.default_observed_class_name].compact
    end
  end
  
  def update(observed_method, object) #:nodoc
    send(observed_method, object) if respond_to?(observed_method)
  end
  
  def observed_class_inherited(subclass)
    add_observer!(subclass)
  end
  
  # for compatibility with ActiveRecord::Observer and specs that work with it
  def observed_classes
    Set.new(observed_class_names.map{|observed_class_name| observed_class_name.constantize })
  end

  def observed_subclasses
    observed_classes.sum([]) { |klass| klass.send(:subclasses) }
  end
  
  def name
    self.class.name
  end
  
protected

  def add_observer!(klass)
    klass.add_observer(self)
    
    # Parallel same smelly code that exists in ActiveRecord::Observer
    if respond_to?(:after_find) && !klass.method_defined?(:after_find)
      klass.class_eval 'def after_find() end'
    end
  end
end