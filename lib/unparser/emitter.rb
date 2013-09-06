module Unparser

  # Emitter base class
  class Emitter
    include Adamantium::Flat, AbstractType, Constants
    include Concord.new(:node, :parent)

    # Registry for node emitters
    REGISTRY = {}

    NOINDENT = [:rescue, :ensure].to_set

    DEFAULT_DELIMITER = ', '.freeze

    CURLY_BRACKETS = IceNine.deep_freeze(%w({ }))

    # Define remaining children
    #
    # @param [Enumerable<Symbol>] names
    #
    # @return [undefined]
    #
    # @api private
    #
    def self.define_remaining_children(names)
      define_method(:remaining_children) do
        children[names.length..-1]
      end
      private :remaining_children
    end
    private_class_method :define_remaining_children

    # Define named child
    #
    # @param [Symbol] name
    # @param [Fixnum] index
    #
    # @return [undefined]
    #
    # @api private
    #
    def self.define_child(name, index)
      define_method(name) do
        children.at(index)
      end
      protected name
    end
    private_class_method :define_child

    # Create name helpers
    #
    # @return [undefined]
    #
    # @api private
    #
    def self.children(*names)
      define_remaining_children(names)

      names.each_with_index do |name, index|
        define_child(name, index)
      end
    end
    private_class_method :children

    # Register emitter for type
    #
    # @param [Symbol] type
    #
    # @return [undefined]
    #
    # @api private
    #
    def self.handle(*types)
      types.each do |type|
        REGISTRY[type] = self
      end
    end
    private_class_method :handle

    # Trigger write to buffer
    #
    # @return [self]
    #
    # @api private
    #
    def write_to_buffer
      emit_surrounding_comments { dispatch }
      self
    end
    memoize :write_to_buffer

    # Emit node
    #
    # @return [self]
    #
    # @api private
    #
    def self.emit(*arguments)
      new(*arguments).write_to_buffer
    end

    # Return emitter
    #
    # @return [Emitter]
    #
    # @api private
    #
    def self.emitter(node, parent)
      type = node.type
      klass = REGISTRY.fetch(type) do
        raise ArgumentError, "No emitter for node: #{type.inspect}"
      end
      klass.new(node, parent)
    end

    # Dispatch node
    #
    # @return [undefined]
    #
    # @api private
    #
    abstract_method :dispatch

    # Return node
    #
    # @return [Parser::AST::Node] node
    #
    # @api private
    #
    attr_reader :node

    # Test if node is emitted as terminated expression
    #
    # @return [false]
    #   if emitted node is unambigous
    #
    # @return [true]
    #
    # @api private
    #
    def terminated?
      TERMINATED.include?(node.type)
    end

  protected

    # Return buffer
    #
    # @return [Buffer] buffer
    #
    # @api private
    #
    def buffer
      parent.buffer
    end
    memoize :buffer, :freezer => :noop

    def comments_left
      parent.comments_left
    end
    memoize :comments_left, :freezer => :noop

  private

    # Emit contents of block within parentheses
    #
    # @return [undefined]
    #
    # @api private
    #
    def parentheses(open=M_PO, close=M_PC)
      write(open)
      yield
      write(close)
    end

    # Emit nodes source map
    #
    # @return [undefined]
    #
    # @api private
    #
    def emit_source_map
      SourceMap.emit(node, buffer)
    end

    # Visit node
    #
    # @param [Parser::AST::Node] node
    #
    # @return [undefined]
    #
    # @api private
    #
    def visit(node)
      emitter = emitter(node)
      emitter.write_to_buffer
    end

    # Visit unambigous node
    #
    # @param [Parser::AST::Node] node
    #
    # @return [undefined]
    #
    # @api private
    #
    def visit_terminated(node)
      emitter = emitter(node)
      maybe_parentheses(!emitter.terminated?) do
        emitter.write_to_buffer
      end
      emitter.write_to_buffer
    end

    # Visit within parentheses
    #
    # @param [Parser::AST::Node] node
    #
    # @return [undefined]
    #
    # @api private
    #
    def visit_parentheses(node, *arguments)
      parentheses(*arguments) do
        visit(node)
      end
    end

    # Call block in optional parentheses
    #
    # @param [true, false] flag
    #
    # @return [undefined]
    #
    # @api private
    #
    def maybe_parentheses(flag)
      if flag
        parentheses { yield }
      else
        yield
      end
    end

    # Return emitter for node
    #
    # @param [Parser::AST::Node] node
    #
    # @return [Emitter]
    #
    # @api private
    #
    def emitter(node)
      self.class.emitter(node, self)
    end

    # Emit delimited body
    #
    # @param [Enumerable<Parser::AST::Node>] nodes
    # @param [String] delimiter
    #
    # @return [undefined]
    #
    # @api private
    #
    def delimited(nodes, delimiter = DEFAULT_DELIMITER)
      max = nodes.length - 1
      nodes.each_with_index do |node, index|
        visit(node)
        write(delimiter) if index < max
      end
    end

    # Return children of node
    #
    # @return [Array<Parser::AST::Node>]
    #
    # @api private
    #
    def children
      node.children
    end

    # Write newline
    #
    # @return [undefined]
    #
    # @api private
    #
    def nl
      buffer.nl
    end

    # Write strings into buffer
    #
    # @return [undefined]
    #
    # @api private
    #
    def write(*strings)
      strings.each do |string|
        buffer.append(string)
      end
    end

    # Write end keyword
    #
    # @return [undefined]
    #
    # @api private
    #
    def k_end
      write(K_END)
    end

    # Return first child
    #
    # @return [Parser::AST::Node]
    #   if present
    #
    # @return [nil]
    #   otherwise
    #
    # @api private
    #
    def first_child
      children.first
    end

    # Write whitespace
    #
    # @return [undefined]
    #
    # @api private
    #
    def ws
      write(WS)
    end

    # Call emit contents of block indented
    #
    # @return [undefined]
    #
    # @api private
    #
    def indented
      buffer = self.buffer
      buffer.indent
      yield
      buffer.unindent
    end

    def emit_surrounding_comments
      loc = node.location
      return yield if loc.nil?

      if buffer.fresh_line?
        begin_pos = loc.expression.begin_pos
        comment_before_count = comments_left.index { |comment| comment.location.expression.begin_pos > begin_pos } || comments_left.size
        comments_before = comments_left.shift(comment_before_count)
        comments_before.each do |comment|
          write(comment.text)
          nl
        end
      end

      yield

      node_range = loc.expression
      end_line = node_range.end.line
      last_pos_emitted = node_range.end_pos
      while comments_left.size > 0 && comments_left.first.location.expression.line <= end_line
        comment = comments_left.shift
        buffer.append_to_end_of_line(WS + comment.text)
        last_pos_emitted = [last_pos_emitted, comment.location.expression.end_pos].max
      end

      while comments_left.size > 0
        comment_range = comments_left.first.location.expression
        range_between = Parser::Source::Range.new(comment_range.source_buffer, last_pos_emitted, comment_range.begin_pos)
        if range_between.source =~ /\A\s*\Z/
          comment = comments_left.shift
          buffer.append_to_end_of_line(NL + comment.text)
          last_pos_emitted = comment_range.end_pos
        else
          break
        end
      end
    end

    # Emit non nil body
    #
    # @param [Parser::AST::Node] node
    #
    # @return [undefined]
    #
    # @api private
    #
    def emit_body(body = self.body)
      unless body
        nl
        return
      end
      visit_indented(body)
    end

    # Visit indented node
    #
    # @param [Parser::AST::Node] node
    #
    # @return [undefined]
    #
    # @api private
    #
    def visit_indented(node)
      if NOINDENT.include?(node.type)
        visit(node)
      else
        indented { visit(node) }
      end
    end

    # Return parent type
    #
    # @return [Symbol]
    #   if parent is present
    #
    # @return [nil]
    #   otherwise
    #
    # @api private
    #
    def parent_type
      parent && parent.node && parent.node.type
    end

    # Helper for building nodes
    #
    # @param [Symbol]
    #
    # @return [Parser::AST::Node]
    #
    # @api private
    #
    def s(type, *children)
      Parser::AST::Node.new(type, *children)
    end

    # Emitter that fully relies on parser source maps
    class SourceMap < self

      # Perform dispatch
      #
      # @param [Node] node
      # @param [Buffer] buffer
      #
      # @return [self]
      #
      # @api private
      #
      def self.emit(node, buffer)
        buffer.append(node.location.expression.source)
        self
      end

    end # SourceMap
  end # Emitter
end # Unparser
