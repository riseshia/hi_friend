module HiFriend
  class LocToNodeMapper
    class << self
      def lookup(node, text, pos)
        target_node = node

        loop do
          next_node = target_node.compact_child_nodes.find do |child|
            in_range?(child, pos)
          end

          break if next_node.nil?

          target_node = next_node
        end

        case target_node
        when Prism::DefNode, Prism::ClassNode, Prism::ModuleNode, Prism::SingletonClassNode
          whitespace?(text, pos) ? nil : target_node
        else
          target_node
        end

      end

      WHITESPACE_REGEXP = /\s/
      private def whitespace?(text, pos)
        line = text.lines[pos.lineno - 1]
        return false if line.nil?
        WHITESPACE_REGEXP.match?(line[pos.column])
      end

      private def in_range?(node, pos)
        loc = node.location
        lineno = pos.lineno
        column = pos.column


        return false if loc.start_line > lineno || lineno > loc.end_line
        return false if loc.start_line == lineno && column < loc.start_column
        return false if loc.end_line == lineno && column > loc.end_column

        true
      end
    end
  end
end
