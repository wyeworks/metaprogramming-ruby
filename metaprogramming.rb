class PreconditionError < StandardError; end
class PostconditionError < StandardError; end

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
    # Save the current precondition and reset it
    preconditions = @current_preconditions
    @current_preconditions = []
    # Save the current postcondition and reset it
    postconditions = @current_postconditions
    @current_postconditions = []

    # Redefine the method to include the precondition
    original_method = instance_method(method_name)
    define_method(method_name) do |*args, &method_block|
      puts "Executing preconditions for #{method_name} - preconditions: #{preconditions&.count}"
      # Preconditions execution
      raise PreconditionError, "Some precondition failed for #{method_name}" unless preconditions.nil? || preconditions.all? { |pc| instance_exec(*args, &pc) }
      puts "Executing method #{method_name}"
      # Original method execution
      ret = original_method.bind(self).call(*args, &method_block)
      puts "Executing postconditions for #{method_name}"
      # Postconditions execution
      raise PostconditionError, "Some postcondition failed for #{method_name}" unless postconditions.nil? || postconditions&.all? { |pc| instance_exec(*args, &pc) }

      ret
    end
  end
end

class Node
  def initialize(element, next_node)
    @element = element
    @next_node = next_node
  end

  def size
    next_node.nil? ? 1 : 1 + next_node.size
  end

  attr_reader :element, :next_node
end

# Sample usage class
class Stack
  attr_accessor :current_node, :capacity
  pre { |capacity| capacity > 0 }
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
    empty? ? 0 : current_node.size
  end

  def empty?
    current_node.nil?
  end

  def full?
    height == capacity
  end
end
