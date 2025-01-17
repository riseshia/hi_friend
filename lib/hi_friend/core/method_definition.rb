module HiFriend::Core
  class MethodDefinitionBase
  end

  class MethodDefinition < MethodDefinitionBase
    attr_accessor :required_positionals, :optional_positionals,
                  :required_keywords, :optional_keywords,
                  :rest_positionals, :rest_keywords,
                  :trailing_positionals,
                  :return_type,
                  :visibility

    def initialize
      @required_positionals = {}
      @optional_positionals = {}
      @required_keywords = {}
      @optional_keywords = {}
      @rest_positionals = {}
      @rest_keywords = {}
      @trailing_positionals = {}
      @return_type = Type.any
      @visibility = :public
    end

    def any_method? = false
  end

  # method definition which can not define args, such as `__send__`
  class AnyFunction < MethodDefinitionBase
    attr_accessor :return_type, :visibility

    def initialize
      @return_type = Type.any
      @visibility = :public
    end

    def any_method? = true
  end
end
