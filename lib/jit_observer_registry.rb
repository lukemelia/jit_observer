class JitObserverRegistry

  def self.register(observer_instance)
    observer_instance.observed_class_names.each do |observed_class_name|
      registry[observed_class_name] << observer_instance.class.name
    end
  end
  
  def self.observers_for(klass)
    registry[klass.name].map do |observer_class_name|
      observer_class_name.constantize.instance
    end
  end
  
  def self.registry
    @registry ||= Hash.new { |hash, key| hash[key] = [] }
  end
    
end