module HiFriend
  class RbsTypeConverter
    Type = HiFriend::Core::Type

    class << self
      def convert(rbs_type)
        case rbs_type
        when RBS::Types::Bases::Any, RBS::Types::Bases::Top, RBS::Types::Bases::Bottom then Type.any
        when RBS::Types::Bases::Self then Type.self0
        when RBS::Types::Bases::Class then Type.class0
        when RBS::Types::Bases::Instance then Type.instance
        when RBS::Types::Bases::Void then Type.void
        when RBS::Types::Bases::Nil then Type.nil
        when RBS::Types::Bases::Bool then Type.bool
        else
          name = rbs_type.to_s.sub("::", "")
          Type.const(name, singleton: false)
        end
      end
    end
  end
end
