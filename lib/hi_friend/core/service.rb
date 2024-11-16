module HiFriend::Core
  class Service
    def initialize
      # do something
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
      # XXX
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

    def hover(path, pos)
      # XXX
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
