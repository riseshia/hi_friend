module HiFriend::Core
  module ReceiverGuesser
    class << self
      def guess(db:, respond_methods:)
        return nil if respond_methods.empty?

        rows = ReceiverRespond.receivers_respond_to(db: db, method_names: respond_methods)

        return Type.any if rows.empty?
        return Type.class_receiver(rows.first) if rows.size == 1

        # If there are multiple matches, check if they have same parent
        rows = ReceiverRespond.receivers_respond_to(db: db, method_names: respond_methods, self_only: true)
        return Type.any if rows.empty?

        # XXX: If there are multiple matches, return nil
        return Type.any if rows.size > 1

        receiver = Receiver.find_by_fqname(db: db, fqname: rows.first)

        if receiver.kind == "Class"
          return Type.class_receiver(receiver.fqname)
        elsif receiver.kind == "Module"
          # XXX: We need to handle this on someday.
          # return receiver.fqname
          Type.any
        else
          # Unreachable code..
          raise "Unknown receiver kind: #{receiver.kind}"
        end
      end
    end
  end
end
