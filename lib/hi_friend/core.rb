require "prism"

require_relative "core/constant"
require_relative "core/method"
require_relative "core/type"
require_relative "core/type_variable"

require_relative "core/const_registry"
require_relative "core/method_registry"
require_relative "core/service"
require_relative "core/type_variable_registry"
require_relative "core/visitor"

module HiFriend::Core
  module_function

  def const_registry
    @const_registry ||= ConstRegistry.new
  end

  def method_registry
    @method_registry ||= MethodRegistry.new
  end

  def type_variable_registry
    @type_variable_registry ||= TypeVariableRegistry.new
  end

  def create_visitor(
    const_registry:,
    method_registry:,
    type_var_registry:,
    file_path:
  )
    Visitor.new(
      const_registry: const_registry,
      method_registry: method_registry,
      type_var_registry: type_var_registry,
      file_path: file_path
    )
  end
end
