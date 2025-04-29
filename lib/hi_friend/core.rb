require "digest/sha2"

require "prism"

require_relative "core/receiver"
require_relative "core/included_module"
require_relative "core/method_model"

require_relative "core/constant"
require_relative "core/interface"
require_relative "core/method"
require_relative "core/method_definition"
require_relative "core/type"
require_relative "core/type_vertex"
require_relative "core/global_env"

require_relative "core/storage"

require_relative "core/const_registry"
require_relative "core/method_registry"
require_relative "core/node_registry"
require_relative "core/interface_registry"
require_relative "core/service"
require_relative "core/type_vertex_registry"
require_relative "core/visitor"

require_relative "core/call_hook"
require_relative "core/call_hook/attr_reader"
require_relative "core/call_hook/attr_writer"
require_relative "core/call_hook/attr_accessor"
require_relative "core/call_hook/method_visibility"
require_relative "core/call_hook/module_include"
require_relative "core/call_hook/module_extend"
require_relative "core/call_hook/module_function"
require_relative "core/call_hook/normal_method" # This should be required at last

module HiFriend::Core
  Source = Data.define(:path, :hash)

  module_function

  def db
    @db ||= Storage.new
  end

  def const_registry
    @const_registry ||= ConstRegistry.new
  end

  def method_registry
    @method_registry ||= MethodRegistry.new
  end

  def type_vertex_registry
    @type_vertex_registry ||= TypeVertexRegistry.new
  end

  def node_registry
    @node_registry ||= NodeRegistry.new
  end

  def build_source(path, code)
    Source.new(path: path, hash: Digest::SHA256.hexdigest(code))
  end
end
