module HiFriend::Core
  module ReceiverRespondPatcher
    class << self
      def with(db:, file_paths:)
        names = Receiver.receiver_names_by_paths(db: db, paths: file_paths)

        names.each do |name|
          with_per_receiver_name(db: db, receiver_fqname: name)
        end
      end

      def with_per_receiver_name(db:, receiver_fqname:)
        receiver = Receiver.find_by_fqname(db: db, fqname: receiver_fqname)

        source_by_fqname = {
          receiver.fqname => { receiver: receiver, kind: "self" }
        }

        anscestors = retrieve_ancesters(db: db, receiver: receiver)
        anscestors.each do |ancestor|
          source_by_fqname[ancestor.fqname] = { receiver: ancestor, kind: "inherit" }
        end

        inherit_chain_fqnames = [receiver.fqname] + anscestors.map(&:fqname)

        included_modules = IncludedModule.where(db: db, kind: "mixin", target_fqname: inherit_chain_fqnames)
        included_modules.each do |included_module|
          module_receiver = Receiver.resolve_name_to_receiver(
            db: db,
            eval_scope: included_module.eval_scope,
            name: included_module.passed_name,
          )
          source_by_fqname[module_receiver.fqname] = {
            receiver: module_receiver,
            kind: included_module.kind,
          }
        end

        source_by_rid = source_by_fqname.values.each_with_object({}) do |s, h|
          h[s[:receiver].id] = s
        end
        receiver_ids = source_by_fqname.values.map { |r| r[:receiver].id }

        responds = []
        MethodModel.where(db: db, receiver_id: receiver_ids).each do |method|
          s = source_by_rid[method.receiver_id]
          kind = s[:kind]

          responds << [receiver_fqname, method.name, kind]
        end

        ReceiverRespond.insert_bulk(db: db, rows: responds)
      end

      def retrieve_ancesters(db:, receiver:)
        ancestors = []
        target_fqname = receiver.unwrap_fqname_if_singleton
        is_singleton = receiver.is_singleton

        loop do
          included_module = IncludedModule.where(db: db, kind: :inherit, target_fqname: target_fqname).first
          break if included_module.nil?

          parent_receiver = Receiver.resolve_name_to_receiver(
            db: db,
            eval_scope: included_module.eval_scope,
            name: included_module.passed_name,
          )
          if is_singleton
            parent_receiver = Receiver.find_by_fqname(db: db, fqname: parent_receiver.singleton_fqname)
          end

          ancestors << parent_receiver
          target_fqname = parent_receiver.unwrap_fqname_if_singleton
        end

        ancestors
      end
    end
  end
end
