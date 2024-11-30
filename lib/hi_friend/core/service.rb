module HiFriend::Core
  class Service
    def initialize
      @code_ast_per_file = {}
    end

    def add_workspace(rb_folder)
      prefixs = ["/app", "/lib"] # XXX: to be deleted?
      prefixs.each do |prefix|
        Dir.glob(File.expand_path(rb_folder + prefix + "/**/*.rb")) do |path|
          HiFriend::Logger.info("add file #{path}")
          update_rb_file(path, nil)
        end
      end
    end

    def update_rb_file(path, code)
      parse_result =
        if code
          Prism.parse(code)
        else
          Prism.parse_file(path)
        end

      if @code_ast_per_file.key?(path)
        remove_old_version(path)
      end
      @code_ast_per_file[path] = parse_result.value

      visitor = Visitor.new(
        const_registry: HiFriend::Core.const_registry,
        method_registry: HiFriend::Core.method_registry,
        type_var_registry: HiFriend::Core.type_variable_registry,
        file_path: path,
      )
      # pp parse_result.value
      parse_result.value.accept(visitor)
    end

    def remove_old_version(path)
      HiFriend::Core.const_registry.remove_by_path(path)
      HiFriend::Core.method_registry.remove_by_path(path)
      HiFriend::Core.type_variable_registry.remove_by_path(path)
    end

    def diagnostics(path, &blk)
      # XXX
    end

    def definitions(path, pos)
      []
    end

    def type_definitions(path, pos)
      []
    end

    def references(path, pos)
      []
    end

    def rename(path, pos)
      # XXX
    end

    def hover(text, pos)
      code_ast = @code_ast_per_file.fetch(text.path)
      node = HiFriend::LocToNodeMapper.lookup(code_ast, text, pos)
      tvar = HiFriend::Core.type_variable_registry.find(node.node_id)
      tvar.infer.to_human_s
    end

    def code_lens(path)
      # XXX
    end

    def completion(path, trigger, pos)
      # XXX
    end

    def dump_declarations(path)
      []
    end

    def get_method_sig(cpath, singleton, mid)
      []
    end
  end
end
