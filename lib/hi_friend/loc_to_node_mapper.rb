module HiFriend
  class LocToNodeMapper
    class << self
      def lookup(node, pos)
        target_node = node

        loop do
          next_node = target_node.compact_child_nodes.find do |child|
            in_range?(child, pos)
          end

          break if next_node.nil?

          target_node = next_node
        end

        target_node
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
