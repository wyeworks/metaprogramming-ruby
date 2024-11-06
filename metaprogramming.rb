class Module
  def pre(&block)
    @current_preconditions ||= []
    @current_preconditions << block
  end

  def method_added(method_name)
    return unless @current_preconditions&.any?
    # Save the current precondition and reset it
    preconditions = @current_preconditions
    @current_preconditions = []

    # Redefine the method to include the precondition
    original_method = instance_method(method_name)
    define_method(method_name) do |*args, &method_block|
      # Preconditions execution
      raise "Some precondition failed for #{method_name}" unless preconditions.all? { |pc| instance_exec(*args, &pc) }
      # Original method execution
      original_method.bind(self).call(*args, &method_block)
    end
  end
end

class A
  pre { |x| x >= 0 }
  pre { |x| x <= 10 }
  def method1(x)
    pp "Running method1 with #{x}, between 0 and 10"
  end

  pre { |x| x.is_a?(String) }
  def method2(x)
    pp x
  end

  pre { true_precondition }
  def method3(x)
    pp x
  end

  pre { false_precondition }
  def method4(x)
    pp x
  end

  def true_precondition
    true
  end

  def false_precondition
    false
  end
end
