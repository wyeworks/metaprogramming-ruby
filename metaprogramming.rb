class PreconditionError < StandardError
  def initialize(method_name, precondition_index)
    super("Precondition #{precondition_index} failed for #{method_name}")
  end
end
class PostconditionError < StandardError
  def initialize(method_name, postcondition_index)
    super("Postcondition #{postcondition_index} failed for #{method_name}")
  end
end

class Module
  def pre(&block)
    @current_preconditions ||= []
    @current_preconditions << block
  end

  def post(&block)
    @current_postconditions ||= []
    @current_postconditions << block
  end

  def method_added(method_name)
    return unless @current_preconditions&.any? || @current_postconditions&.any?

    preconditions = @current_preconditions
    @current_preconditions = []
    postconditions = @current_postconditions
    @current_postconditions = []

    original_method = instance_method(method_name)
    define_method(method_name) do |*args, &method_block|
      puts "Executing preconditions for #{method_name} - preconditions: #{preconditions&.count}"
      preconditions.each_with_index do |pc, index|
        raise PreconditionError.new(method_name, index + 1) unless instance_exec(*args, &pc)
      end

      puts "Executing method #{method_name}"
      ret = original_method.bind(self).call(*args, &method_block)

      puts "Executing postconditions for #{method_name}"
      postconditions.each_with_index do |pc, index|
        raise PostconditionError.new(method_name, index + 1) unless instance_exec(*args, &pc)
      end

      ret
    end
  end
end

# Sample usage class
class Stack
  attr_accessor :current_node, :capacity
  pre { |capacity_param| capacity_param > 0 }
  post { empty? }
  def initialize(capacity)
    @capacity = capacity
    @current_node = nil
    puts "Initialized stack with capacity: #{@capacity}"
  end

  pre { !full? }
  def push(element)
    puts "Pushing element: #{element}"
    @current_node = Node.new(element, current_node)
  end

  pre { !empty? }
  def pop
    element = top
    @current_node = current_node.next_node
    puts "Popped element: #{element}"
    element
  end

  pre { !empty? }
  def top
    current_node.element
  end

  def height
    empty? ? 0 : current_node.chain_size
  end

  def empty?
    current_node.nil?
  end

  def full?
    height == capacity
  end

  Node = Struct.new(:element, :next_node) do
    def chain_size
      next_node.nil? ? 1 : 1 + next_node.size
    end
  end
end
