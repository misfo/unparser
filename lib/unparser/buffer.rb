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

    def insert_before_newlines(string)
      newlines = @content[/\n*\Z/].size
      if newlines == 0
        raise "Expected buffer to end with a newline"
      end
      @content.insert((-1 - newlines), string)
      self
    end

    # Increase indent
    #
    # @return [self]
    #
    # @api private
    #
    def indent
      nl
      @indent+=1
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
      @content << NL
      self
    end

    # Return content of buffer
    #
    # @return [String]
    #
    # @api private
    #
    def content
      @content.dup.freeze
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
