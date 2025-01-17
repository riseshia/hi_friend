module HiFriend
  class RbsTypeConverter
    Type = HiFriend::Core::Type

    class << self
      def convert(builder, rbs_type)
        case rbs_type
        when RBS::Types::Bases::Any, RBS::Types::Bases::Top, RBS::Types::Bases::Bottom then Type.any
        when RBS::Types::Bases::Self then Type.self0
        when RBS::Types::Bases::Class then Type.class0
        when RBS::Types::Bases::Instance then Type.instance
        when RBS::Types::Bases::Void then Type.void
        when RBS::Types::Bases::Nil then Type.nil
        when RBS::Types::Bases::Bool then Type.bool
        when RBS::Types::ClassSingleton
          name = rbs_type.to_s.sub("::", "")
          Type.const(name[10...-1], singleton: true)
        when RBS::Types::ClassInstance
          name = rbs_type.to_s.sub("::", "")
          Type.const(name, singleton: false)
        when RBS::Types::Alias
          # some rbs type alias raises error with expand_alias,
          # so handle it separately.
          # I'm not sure if this is a bug in RBS or not. ;)
          case rbs_type.name.name
          when :symbol
            Type.const("Symbol", singleton: false)
          when :hash # XXX: to be implemented
            Type.const("Hash", singleton: false)
          when :range # XXX: to be implemented
            Type.any
          when :array # XXX: to be implemented
            Type.any
          else
            union_or_not = builder.expand_alias(rbs_type.name)

            if union_or_not.is_a?(RBS::Types::Union)
              types = union_or_not.types.map { |rt| convert(builder, rt) }
              Type.union(types)
            else
              convert(builder, union_or_not)
            end
          end
        when RBS::Types::Interface
          name = rbs_type.to_s.sub("::", "")
          Type.interface(name)
        else
          # pp rbs_type
          # raise "Unknown RBS type: #{rbs_type.class}"
          name = rbs_type.to_s.sub("::", "")
          Type.const(name, singleton: false)
        end
      end
    end
  end
end
