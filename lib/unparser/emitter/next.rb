module Unparser
  class Emitter
    # Emitter for next nodes
    class Next < self

      handle :next

    private

      # Perform dispatch
      #
      # @return [undefined]
      #
      # @api private
      #
      def dispatch
        write(K_NEXT)
        return if children.empty?
        parentheses { visit(children.first) }
      end

    end # Next
  end # Emitter
end # Unparser
