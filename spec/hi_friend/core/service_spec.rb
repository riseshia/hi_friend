# frozen_string_literal: true

module HiFriend::Core
  describe Service do
    let(:const_registry) { HiFriend::Core.const_registry }
    let(:method_registry) { HiFriend::Core.method_registry }
    let(:type_vertex_registry) { HiFriend::Core.type_vertex_registry }
    let(:service) do
      Service.new
    end

    before(:each) do
      HiFriend::Core.const_registry.clear
      HiFriend::Core.method_registry.clear
      HiFriend::Core.type_vertex_registry.clear
    end

    describe "#update_rb_file" do
      context "with code change" do
        context "rename class name" do
          let(:code) do
            <<~CODE
              class A
              end
            CODE
          end

          let(:new_code) do
            <<~CODE
              class B
              end
            CODE
          end

          it "const_registry has consistency" do
            service.update_rb_file("test_file.rb", code)
            expect(const_registry.find("A")).not_to be_nil

            service.update_rb_file("test_file.rb", new_code)
            expect(const_registry.find("A")).to be_nil
            expect(const_registry.find("B")).not_to be_nil
          end
        end

        context "rename method name" do
          let(:code) do
            <<~CODE
              def method_a
                1
              end
            CODE
          end

          let(:new_code) do
            <<~CODE
              def method_b
                1
              end
            CODE
          end

          it "method_registry has consistency" do
            service.update_rb_file("test_file.rb", code)
            expect(method_registry.find("Object", "method_a", visibility: :public)).not_to be_nil

            service.update_rb_file("test_file.rb", new_code)
            expect(method_registry.find("Object", "method_a", visibility: :public)).to be_nil
            expect(method_registry.find("Object", "method_b", visibility: :public)).not_to be_nil
          end
        end

        context "rename var name" do
          let(:code) do
            <<~CODE
              def method_a
                var_a = 1
              end
            CODE
          end

          let(:new_code) do
            <<~CODE
              def method_b
                var_b = 2
              end
            CODE
          end

          it "type_vertex_registry has consistency" do
            service.update_rb_file("test_file.rb", code)
            var_a, one = type_vertex_registry.all

            expect(var_a.name).to eq("var_a")
            expect(one.name).to eq("1")

            service.update_rb_file("test_file.rb", new_code)
            var_b, two = type_vertex_registry.all

            expect(var_b.name).to eq("var_b")
            expect(two.name).to eq("2")
          end
        end

        context "module open on files" do
          let(:file_a) do
            <<~CODE
              module A
                class Foo; end
              end
            CODE
          end

          let(:file_b) do
            <<~CODE
              module A
                class Bar; end
              end
            CODE
          end

          let(:file_a_new) do
            <<~CODE
              class Foo
              end
            CODE
          end

          let(:file_b_new) do
            <<~CODE
              class Bar
              end
            CODE
          end

          it "const_registry has consistency" do
            service.update_rb_file("a.rb", file_a)
            service.update_rb_file("b.rb", file_b)

            expect(const_registry.find("A")).not_to be_nil
            expect(const_registry.find("A::Foo")).not_to be_nil
            expect(const_registry.find("A::Bar")).not_to be_nil

            service.update_rb_file("b.rb", file_b_new)
            expect(const_registry.find("A")).not_to be_nil
            expect(const_registry.find("Bar")).not_to be_nil
            expect(const_registry.find("A::Foo")).not_to be_nil
            expect(const_registry.find("A::Bar")).to be_nil

            service.update_rb_file("a.rb", file_a_new)
            expect(const_registry.find("A")).to be_nil
            expect(const_registry.find("Foo")).not_to be_nil
            expect(const_registry.find("A::Foo")).to be_nil
            expect(const_registry.find("A::Bar")).to be_nil
          end
        end

        context "class open on files" do
          let(:file_a) do
            <<~CODE
              class Foo
                def method_from_a
                  1
                end
              end
            CODE
          end

          let(:file_b) do
            <<~CODE
              class Foo
                def method_from_b
                  1
                end
              end
            CODE
          end

          let(:file_a_new) do
            <<~CODE
              class Bar
              end
            CODE
          end

          let(:file_b_new) do
            <<~CODE
              class Bar
              end
            CODE
          end

          it "const_registry has consistency" do
            service.update_rb_file("a.rb", file_a)
            service.update_rb_file("b.rb", file_b)

            expect(const_registry.find("Foo")).not_to be_nil
            expect(method_registry.find("Foo", "method_from_a", visibility: :public)).not_to be_nil
            expect(method_registry.find("Foo", "method_from_b", visibility: :public)).not_to be_nil

            service.update_rb_file("b.rb", file_b_new)
            expect(const_registry.find("Foo")).not_to be_nil
            expect(method_registry.find("Foo", "method_from_a", visibility: :public)).not_to be_nil
            expect(method_registry.find("Foo", "method_from_b", visibility: :public)).to be_nil
            expect(const_registry.find("Bar")).not_to be_nil

            service.update_rb_file("a.rb", file_a_new)
            expect(const_registry.find("Foo")).to be_nil
            expect(method_registry.find("Foo", "method_from_a", visibility: :public)).to be_nil
            expect(method_registry.find("Foo", "method_from_b", visibility: :public)).to be_nil
            expect(const_registry.find("Bar")).not_to be_nil
          end
        end
      end
    end
  end
end
