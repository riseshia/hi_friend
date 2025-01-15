module HiFriend::Core
  class Service
    def initialize
      @code_ast_per_file = {}
      @global_env = GlobalEnv.load!
    end

    def add_workspace(rb_folder)
      load_global_env_to_registry

      prefixs = ["/app", "/lib"] # XXX: to be deleted?
      updated_file_paths = []
      prefixs.each do |prefix|
        Dir.glob(File.expand_path(rb_folder + prefix + "/**/*.rb")) do |path|
          updated_file_paths << path
          HiFriend::Logger.info("add file #{path}")
          # delay update inference to do it at once after all files are added
          update_rb_file(path, nil, update_inference: false)
        end
      end

      update_inference(updated_file_paths)
    end

    def load_global_env_to_registry
      @global_env.consts.each do |const|
        const.paths.each do |const_path|
          HiFriend::Core.const_registry.create(const.name, nil, const_path, kind: const.kind)
        end
      end

      @global_env.methods.each do |method|
        HiFriend::Core.method_registry.add(
          receiver_name: method.receiver_name,
          name: method.name,
          node: nil,
          path: method.path,
          singleton: method.singleton,
          visibility: method.visibility,
          type: method.type,
        )
      end
    end

    def update_rb_file(path, code, update_inference: false)
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
        type_vertex_registry: HiFriend::Core.type_vertex_registry,
        node_registry: HiFriend::Core.node_registry,
        file_path: path,
      )
      # pp parse_result.value
      parse_result.value.accept(visitor)

      if update_inference
        update_inference([path])
      end
    rescue RuntimeError => e
      HiFriend::Logger.error("Failed to update file: #{path}")
      HiFriend::Logger.error(e)
    end

    private def update_inference(paths)
      # phase 1: try fast inference to guess method receiver type.
      HiFriend::Core.type_vertex_registry.each_call_tv do |call_tv|
        call_tv.fast_infer_receiver_type
      end

      # phase 2: do full inference.
      paths.each do |path|
        tvs = HiFriend::Core.type_vertex_registry.find_by_path(path)
        tvs.each(&:infer)
      end
    end

    private def remove_old_version(path)
      HiFriend::Core.const_registry.remove_by_path(path)
      HiFriend::Core.method_registry.remove_by_path(path)
      HiFriend::Core.type_vertex_registry.remove_by_path(path)
      HiFriend::Core.node_registry.remove_by_path(path)
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
      tvar = HiFriend::Core.node_registry.find(node.node_id)
      tvar.hover
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
