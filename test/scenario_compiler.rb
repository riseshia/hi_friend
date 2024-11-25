class ScenarioCompiler
  def initialize(scenarios, output_declarations: false, check_diff: true, fast: true)
    @scenarios = scenarios
    @output_declarations = output_declarations
    @check_diff = check_diff
    @fast = fast
  end

  def compile
    header + @scenarios.map {|scenario| compile_scenario(scenario) }.join("\n") + footer
  end

  def run
    eval(compile)
  end

  def header
    <<~END
      require #{ File.join(__dir__, "../lib/hi_friend").dump }
      require #{ File.join(__dir__, "helper").dump }
      class ScenarioTest < Test::Unit::TestCase
        core = HiFriend::Core::Service.new
        _ = core # stop "unused" warning
    END
  end

  def footer
    <<~END
      end
    END
  end

  def compile_scenario(scenario)
    @file = "test.rb"
    @pos = nil
    out = %(eval(<<'TYPEPROF_SCENARIO_END', nil, #{ scenario.dump }, 1)\n)
    out << %(test(#{ scenario.dump }) do )
    unless @fast
      out << "core = HiFriend::Core::Service.new;"
    end
    close_str = ""
    lineno = 0
    File.foreach(scenario, chomp: true) do |line|
      if line =~ /\A###\s*/
        lineno = 0
        out << close_str
        if line =~ /\A###\s*(\w+)\z/
          ary = send("handle_#{ $1 }").lines.map {|s| s.strip }.join(";").split("DATA")
          raise if ary.size != 2
          open_str, close_str = ary
          out << open_str.chomp
          close_str += "\n"
        else
          raise "unknown directive: #{ line.inspect }"
        end
      else
        raise "NUL found" if line.include?("\0")

        lineno += 1
        if line =~ /{(.)}/
          last_match = Regexp.last_match
          if @pos
            raise "test code includes more than one {x} positions?"
          end

          @pos = [lineno, last_match.offset(0).first]
          line = line.sub(last_match[0], last_match[1])
        end

        out << line.gsub("\\") { "\\\\" } << "\n"
      end
    end
    out << close_str
    if @output_declarations
      out << <<-END
        at_exit do
          puts "---"
          core.diagnostics(#{ @file.dump }) {|diag| pp diag }
        end
      END
    else
      out << "ensure core.reset!\n"
    end
    out << "end\n"
    out << %(TYPEPROF_SCENARIO_END\n)
  end

  def handle_update
    <<-END
#{ @check_diff ? 2 : 1 }.times {|i|
  core.update_rb_file(#{ @file.dump }, %q\0DATA\0)
};
    END
  end

#   def handle_assert
#     <<-END
# output = core.dump_declarations(#{ @file.dump })
# assert_equal(%q\0DATA\0.rstrip, output.rstrip)
# RBS::Parser.parse_signature(output)
#     END
#   end
#
#   def handle_assert_without_validation
#     <<-END
# output = core.dump_declarations(#{ @file.dump })
# assert_equal(%q\0DATA\0.rstrip, output.rstrip)
#     END
#   end
#
#   def handle_diagnostics
#     <<-END
# output = []
# core.diagnostics(#{ @file.dump }) {|diag|
#   output << (diag.code_range.to_s << ': ' << diag.msg)
# }
# output = output.join(\"\\n\")
# assert_equal(%q\0DATA\0.rstrip, output)
#     END
#   end

  def handle_hover
    <<-END
text = HiFriend::LSP::Text.new(#{ @file.dump }, file_body, "somever")
output = core.hover(text, HiFriend::CodePosition.new(#{ @pos.join(",") }))
assert_equal(%q\0DATA\0.strip, output.strip)
    END
  end

#   def handle_code_lens
#     <<-END
# output = []
# core.code_lens(#{ @file.dump }) {|cr, hint| output << (cr.first.to_s + ": " + hint) }
# output = output.join(\"\\n\")
# assert_equal(%q\0DATA\0.rstrip, output)
#     END
#   end
#
#   def handle_completion
#     <<-END
# output = []
# core.completion(#{ @file.dump }, ".", HiFriend::CodePosition.new(#{ @pos.join(",") })) {|_mid, hint| output << hint }
# assert_equal(exp = %q\0DATA\0.rstrip, output[0..exp.count(\"\\n\")].join(\"\\n\"))
#     END
#   end
#
#   def handle_definition
#     <<-END
# output = core.definitions(#{ @file.dump }, HiFriend::CodePosition.new(#{ @pos.join(",") }))
# assert_equal(exp = %q\0DATA\0.rstrip, output.map {|file, cr| file + ":" + cr.to_s }.join(\"\\n\"))
#     END
#   end
#
#   def handle_type_definition
#     <<-END
# output = core.type_definitions(#{ @file.dump }, HiFriend::CodePosition.new(#{ @pos.join(",") }))
# assert_equal(exp = %q\0DATA\0.rstrip, output.map {|file, cr| file + ":" + cr.to_s }.join(\"\\n\"))
#     END
#   end
#
#   def handle_references
#     <<-END
# output = core.references(#{ @file.dump }, HiFriend::CodePosition.new(#{ @pos.join(",") }))
# assert_equal(exp = %q\0DATA\0.rstrip, output.map {|file, cr| file + ":" + cr.to_s }.join(\"\\n\"))
#     END
#   end
#
#   def handle_rename
#     <<-END
# output = core.rename(#{ @file.dump }, HiFriend::CodePosition.new(#{ @pos.join(",") }))
# assert_equal(exp = %q\0DATA\0.rstrip, output.map {|file, cr| file + ":" + cr.to_s }.join(\"\\n\"))
#     END
#   end
end
