require File.dirname(__FILE__) + '/spec_helper'
require 'active_model'
require 'active_model/core'

ActiveModel::Base.send :include, ObserverDisabler
 
class ObservedModel < ActiveModel::Base
  class Observer
  end
end

class FooObserver < JitObserver
  class << self
    public :new
  end
  
  attr_accessor :stub

  def on_spec(record)
    stub.event_with(record) if stub
  end
end

class Foo < ActiveModel::Base
end

describe JitObserver do
  before(:each) do
    ObservedModel.observers = :foo_observer
    Foo.delete_observers
    FooObserver.clear_observed_classes
    JitObserverRegistry.registry.clear
  end

  it "should guess the implicit observable model name" do
    FooObserver.default_observed_class_name.should == 'Foo'
  end

  it "should track implicit observed models" do
    instance = FooObserver.new
    instance.send(:observed_classes).should include(Foo)
    instance.send(:observed_classes).should_not include(ObservedModel)
  end

  it "should track explicitly observed model class" do
    old_instance = FooObserver.new
    old_instance.send(:observed_classes).should_not include(ObservedModel)
  
    FooObserver.observe ObservedModel
    instance = FooObserver.new
    instance.send(:observed_classes).should include(ObservedModel)
  end

  it "should track explicitly observed model as string" do
    old_instance = FooObserver.new
    old_instance.send(:observed_classes).should_not include(ObservedModel)
  
    FooObserver.observe 'ObservedModel'
    instance = FooObserver.new
    instance.send(:observed_classes).should include(ObservedModel)
  end

  it "should track explicitly observed model as symbol" do
    old_instance = FooObserver.new
    old_instance.send(:observed_classes).should_not include(ObservedModel)
  
    FooObserver.observe :observed_model
    instance = FooObserver.new
    instance.send(:observed_classes).should include(ObservedModel)
  end

  it "should call an observer event if it exists" do
    foo = Foo.new
    instance = FooObserver.new
    instance.stub = stub('foo_observer_instance')
    instance.stub.should_receive(:event_with).with(foo)
    Foo.with_observers do
      Foo.send(:changed)
      Foo.send(:notify_observers, :on_spec, foo)
    end
  end

  it "should skip nonexistent observer events without blowing up" do
    foo = Foo.new
    Foo.with_observers do
      Foo.send(:changed)
      Foo.send(:notify_observers, :whatever, foo)
    end
  end
end

