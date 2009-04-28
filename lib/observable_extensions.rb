module Observable
  def inherited(subclass)
    super
    JitObserverRegistry.observers_for(subclass).each do |o|
      o.start_observing(subclass)
    end
    notify_observers :observed_class_inherited, subclass
  end
end