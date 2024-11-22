# frozen_string_literal: true

module HiFriend::Core
  describe Service do
    let(:const_registry) { HiFriend::Core.const_registry }
    let(:method_registry) { HiFriend::Core.method_registry }
    let(:type_var_registry) { HiFriend::Core.type_variable_registry }
    let(:service) do
      Service.new
    end

    before(:each) do
      HiFriend::Core.const_registry.clear
      HiFriend::Core.method_registry.clear
      HiFriend::Core.type_variable_registry.clear
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
            expect(method_registry.find("", "method_a", visibility: :public)).not_to be_nil

            service.update_rb_file("test_file.rb", new_code)
            expect(method_registry.find("", "method_a", visibility: :public)).to be_nil
            expect(method_registry.find("", "method_b", visibility: :public)).not_to be_nil
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

          it "type_var_registry has consistency" do
            service.update_rb_file("test_file.rb", code)
            var_a, one = type_var_registry.all

            expect(var_a.name).to eq("var_a")
            expect(one.name).to eq("1")

            service.update_rb_file("test_file.rb", new_code)
            var_b, two = type_var_registry.all

            expect(var_b.name).to eq("var_b")
            expect(two.name).to eq("2")
          end
        end
      end
    end
  end
end
