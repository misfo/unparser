module Unparser
  class Emitter
    # Emitter for retry nodes
    class Retry < self

      handle :retry

    private

      # Perform dispatch
      #
      # @return [undefined]
      #
      # @api private
      #
      def dispatch
        write(K_RETRY)
      end

    end # Break
  end # Emitter
end # Unparser
