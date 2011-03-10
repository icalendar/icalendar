# A set of methods to help create meta-programming gizmos.
class Object
  # The metaclass is the singleton behind every object.
  def metaclass
    class << self
      self
    end
  end

  # Evaluates the block in the context of the metaclass
  def meta_eval(&blk)
    metaclass.instance_eval(&blk)
  end

  # Acts like an include except it adds the module's methods
  # to the metaclass so they act like class methods.
  def meta_include mod
    meta_eval do
      include mod
    end
  end

  # Adds methods to a metaclass
  def meta_def name, &blk
    meta_eval { define_method name, &blk }
  end

  # Defines an instance method within a class
  def class_def name, &blk
    class_eval { define_method name, &blk }
  end
end
