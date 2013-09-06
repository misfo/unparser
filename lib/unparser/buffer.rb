module Unparser

  # Buffer used to emit into
  class Buffer

    NL = "\n".freeze

    # Initialize object
    #
    # @return [undefined]
    #
    # @api private
    #
    def initialize
      @content = ''
      @line_suffix = ''
      @indent = 0
    end

    # Append string
    #
    # @param [String] string
    #
    # @return [self]
    #
    # @api private
    #
    def append(string)
      if @content[-1] == NL
        prefix
      end
      @content << string
      self
    end

    def fresh_line?
      @content.empty? || @content[-1] == NL
    end

    def append_to_end_of_line(string)
      @line_suffix << string
      self
    end

    # Increase indent
    #
    # @return [self]
    #
    # @api private
    #
    def indent
      @indent+=1
      nl
      self
    end

    # Decrease indent
    #
    # @return [self]
    #
    # @api private
    #
    def unindent
      nl
      @indent-=1
      self
    end

    # Write newline
    #
    # @return [self]
    #
    # @api private
    #
    def nl
      @line_suffix.lines.each do |line|
        append(line)
      end
      @content << NL
      @line_suffix = ''
      self
    end

    # Return content of buffer
    #
    # @return [String]
    #
    # @api private
    #
    def content
      (@content + @line_suffix).freeze
    end

  private

    # Write prefix
    #
    # @return [String]
    #
    # @api private
    #
    def prefix
      @content << '  '*@indent
    end

  end # Buffer
end # Unparser
