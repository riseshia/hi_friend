module HiFriend::Core
  class Service
    def initialize
      # do something
    end

    def add_workspace(rb_folder)
      Dir.glob(File.expand_path(rb_folder + "/**/*.rb")) do |path|
        update_rb_file(path, nil)
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

if $0 == __FILE__
  core = HiFriend::Core::Service.new
  core.add_workspaces(["foo"].to_a)
  core.update_rb_file("foo", "foo")
end
