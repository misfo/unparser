require 'abstract_type'
require 'concord'
require 'parser/all'

# Library namespace
module Unparser

  EMPTY_STRING = ''.freeze

  # Unparse ast into string
  #
  # @param [Parser::Node, nil] node
  #
  # @return [String]
  #
  # @api private
  #
  def self.unparse(node, comments = [])
    if node.nil?
      node = Parser::AST::Node.new(:empty)
    end
    buffer = Buffer.new
    comment_enumerator = CommentEnumerator.new(comments)
    root = Emitter::Root.new(buffer, comment_enumerator)
    Emitter.emitter(node, root).write_to_buffer
    buffer.content
  end

  # Transquote string
  #
  # @param [String] raw_quoted
  # @param [String] current_delimiter
  # @param [String] target_delimiter
  #
  # @return [String]
  #
  # @api private
  #
  def self.transquote(raw_quoted, current_delimiter, target_delimiter)
    raw = raw_quoted.gsub("\\#{current_delimiter}", current_delimiter)
    raw.gsub(target_delimiter, "\\#{target_delimiter}").freeze
  end

end # Unparser

require 'unparser/buffer'
require 'unparser/comment_enumerator'
require 'unparser/constants'
require 'unparser/emitter'
require 'unparser/emitter/literal'
require 'unparser/emitter/literal/primitive'
require 'unparser/emitter/literal/singleton'
require 'unparser/emitter/literal/dynamic'
require 'unparser/emitter/literal/regexp'
require 'unparser/emitter/literal/composed'
require 'unparser/emitter/literal/range'
require 'unparser/emitter/literal/dynamic_body'
require 'unparser/emitter/literal/execute_string'
require 'unparser/emitter/send'
require 'unparser/emitter/send/unary'
require 'unparser/emitter/send/binary'
require 'unparser/emitter/send/index'
require 'unparser/emitter/send/regular'
require 'unparser/emitter/block'
require 'unparser/emitter/assignment'
require 'unparser/emitter/variable'
require 'unparser/emitter/splat'
require 'unparser/emitter/cbase'
require 'unparser/emitter/argument'
require 'unparser/emitter/begin'
require 'unparser/emitter/return'
require 'unparser/emitter/undef'
require 'unparser/emitter/def'
require 'unparser/emitter/class'
require 'unparser/emitter/module'
require 'unparser/emitter/op_assign'
require 'unparser/emitter/defined'
require 'unparser/emitter/hookexe'
require 'unparser/emitter/super'
require 'unparser/emitter/break'
require 'unparser/emitter/retry'
require 'unparser/emitter/redo'
require 'unparser/emitter/next'
require 'unparser/emitter/if'
require 'unparser/emitter/alias'
require 'unparser/emitter/yield'
require 'unparser/emitter/binary'
require 'unparser/emitter/case'
require 'unparser/emitter/for'
require 'unparser/emitter/repetition'
require 'unparser/emitter/root'
require 'unparser/emitter/match'
require 'unparser/emitter/empty'
require 'unparser/emitter/flipflop'
require 'unparser/emitter/rescue'
require 'unparser/emitter/resbody'
require 'unparser/emitter/ensure'
# make it easy for zombie
require 'unparser/finalize'
