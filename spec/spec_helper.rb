require "rubygems"
require "spec"
require 'ostruct'

plugin_root = File.join(File.dirname(__FILE__), '..')
version = ENV['RAILS_VERSION']
version = nil if version and version == ""

# look for a symlink to a copy of the framework
if !version and framework_root = ["#{plugin_root}/rails", "#{plugin_root}/../../rails"].find { |p| File.directory? p }
  puts "found framework root: #{framework_root}"
  # this allows for a plugin to be tested outside of an app and without Rails gems
  $:.unshift "#{framework_root}/activesupport/lib"
  $:.unshift "#{framework_root}/activemodel/lib"
else
  raise "Need a copy of rails to integrate with and run tests"
end

dir = File.dirname(__FILE__)
require File.join(dir, "/../lib/jit_observer.rb")

Spec::Runner.configure do |config|

end

$disable_observers = false

module ObserverDisabler
  module ClassMethods
    def with_observers(*observer_syms)
      $disable_observers = true
      yield
    ensure
      $disable_observers = false
    end
  end
  
  def self.included(base)
    base.extend ClassMethods
  end
end
