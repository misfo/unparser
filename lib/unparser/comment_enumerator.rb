module Unparser
  class CommentEnumerator
    def initialize(comments)
      @comments = comments.dup
    end

    attr_writer :last_source_range_written

    def eol_comments
      if @last_source_range_written
        comments = take_up_to_line @last_source_range_written.end.line
        doc_comments, eol_comments = comments.partition(&:document?)
        doc_comments.reverse.each {|comment| @comments.unshift comment }
        unless eol_comments.empty?
          @last_eol_comment_range_written = eol_comments.last.location.expression
        end
        eol_comments
      else
        []
      end
    end

    def take_while
      array = []
      until @comments.empty?
        bool = yield @comments.first
        break unless bool
        array << @comments.shift
      end
      array
    end

    def take_before(position)
      take_while { |comment| comment.location.expression.end_pos <= position }
    end

    def take_up_to_line(line)
      take_while { |comment| comment.location.expression.line <= line }
    end

    def take_all_contiguous_after
      return [] if @last_source_range_written.nil? && @last_eol_comment_range_written.nil?
      position = [@last_source_range_written, @last_eol_comment_range_written].compact.map(&:end_pos).max
      take_while do |comment|
        comment_range = comment.location.expression
        range_between = Parser::Source::Range.new(comment_range.source_buffer, position, comment_range.begin_pos)
        if range_between.source =~ /\A\s*\Z/
          position = comment_range.end_pos
          true
        end
      end
    end
  end
end