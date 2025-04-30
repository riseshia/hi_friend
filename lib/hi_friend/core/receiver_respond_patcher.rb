module HiFriend::Core
  module ReceiverRespondPatcher
    class << self
      def with(db:, file_paths:)
        names = Receiver.receiver_names_by_paths(db: db, paths: file_paths)

        names.each do |name|
          with_per_receiver_name(db: db, receiver_name: name)
        end
      end

      def with_per_receiver_name(db:, receiver_name:)
        included_modules = IncludedModule.where(db: db, target_fqname: receiver_name)
      end
    end
  end
end
