# A module which adds some generators for hash based accessors.
module HashAttrs

  def hash_reader(hash_sym, syms)
    syms.each do |id|
      id = id.to_s.downcase
      func = Proc.new do
        hash = instance_variable_get(hash_sym)
        hash[id.to_sym] 
      end

      self.send(:define_method, id, func)
    end
  end

  def hash_writer(hash_sym, syms)
    syms.each do |id|
      id = id.to_s.downcase

      func = Proc.new do |val| 
        hash = instance_variable_get(hash_sym)
        hash[id.to_sym] = val 
      end

      self.send(:define_method, id+'=', func)
    end
  end

  def hash_accessor(hash, *syms)
    hash_reader(hash, syms)
    hash_writer(hash, syms)
  end
end

