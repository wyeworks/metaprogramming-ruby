class Module
  def pre(&block)
    @current_precondition = block
  end

  def method_added(method_name)
    return unless @current_precondition
    # Save the current precondition and reset it
    precondition = @current_precondition
    @current_precondition = nil

    # Redefine the method to include the precondition
    original_method = instance_method(method_name)
    define_method(method_name) do |*args, &method_block|
      # Ejecuta la precondición
      raise "Precondition failed for #{method_name}" unless precondition.call(*args)
      # Llama al método original
      original_method.bind(self).call(*args, &method_block)
    end
  end
end

class A
  pre { |x| x > 0 }
  def method1(x)
    pp "Running method1 with #{x}"
  end

  pre { |x| x.is_a?(String) }
  def method2(x)
    pp x
  end
end
