# frozen_string_literal: true

module HiFriend::Core
  describe "ParseReceivers" do
    let(:db) { Storage.db }
    let(:const_registry) { HiFriend::Core.const_registry }
    let(:method_registry) { HiFriend::Core.method_registry }
    let(:type_vertex_registry) { HiFriend::Core.type_vertex_registry }
    let(:node_registry) { NodeRegistry.new }
    let(:source) { HiFriend::Core::Source.new(path: "sample/sample.rb", hash: "1234567890") }

    let(:visitor) do
      Visitor.new(
        db: db,
        const_registry: const_registry,
        method_registry: method_registry,
        type_vertex_registry: type_vertex_registry,
        node_registry: node_registry,
        source: source,
      )
    end

    before(:each) do
      const_registry.clear
      method_registry.clear
      type_vertex_registry.clear
      node_registry.clear

      parse_result = Prism.parse(code)
      parse_result.value.accept(visitor)
    end

    def expect_class_exists(fqname)
      receiver = Receiver.find_by_fqname(db, fqname)
      expect(receiver).not_to be_nil
      expect(receiver.is_singleton).to eq(false)
      expect(receiver.kind).to eq("Class")

      singleton_receiver = Receiver.find_by_fqname(db, "singleton(#{fqname})")
      expect(singleton_receiver).not_to be_nil
      expect(singleton_receiver.is_singleton).to eq(true)
      expect(singleton_receiver.kind).to eq("Class")
    end

    def expect_class_inherits(child_fqname, parent_fqname)
      receiver = Receiver.find_by_fqname(db, child_fqname)
      expect(receiver).not_to be_nil

      inheritance = IncludedModule.where(db: db, kind: :inherit, target_fqname: child_fqname).first
      expect(inheritance).not_to be_nil
      expect(inheritance.passed_name).to eq(parent_fqname)
    end

    def expect_class_includes(child_fqname, passed_name)
      receiver = Receiver.find_by_fqname(db, child_fqname)
      expect(receiver).not_to be_nil

      inheritance = IncludedModule.where(db: db, kind: :mixin, target_fqname: child_fqname).first
      expect(inheritance).not_to be_nil
      expect(inheritance.passed_name).to eq(passed_name)
    end

    def expect_class_extends(child_fqname, passed_name)
      singleton_of_child_fqname = "singleton(#{child_fqname})"
      receiver = Receiver.find_by_fqname(db, singleton_of_child_fqname)
      expect(receiver).not_to be_nil

      inheritance = IncludedModule.where(db: db, kind: :mixin, target_fqname: singleton_of_child_fqname).first
      expect(inheritance).not_to be_nil
      expect(inheritance.passed_name).to eq(passed_name)
    end

    def expect_module_exists(fqname)
      receiver = Receiver.find_by_fqname(db, fqname)
      expect(receiver).not_to be_nil
      expect(receiver.is_singleton).to eq(false)
      expect(receiver.kind).to eq("Module")

      singleton_receiver = Receiver.find_by_fqname(db, "singleton(#{fqname})")
      expect(singleton_receiver).not_to be_nil
      expect(singleton_receiver.is_singleton).to eq(true)
      expect(singleton_receiver.kind).to eq("Class")
    end

    def expect_receiver_responds(fqname, visibility, method_name)
      receiver = Receiver.find_by_fqname(db, fqname)
      expect(receiver).not_to be_nil

      methods = MethodModel.where(db, receiver_id: receiver.id, visibility: visibility, name: method_name)
      expect(methods.size).to eq(1)
    end

    describe "Parse class def" do
      context "when simple class" do
        let(:code) do
          <<~CODE
            class Post
            end
          CODE
        end

        it "registers one class" do
          expect_class_exists("Post")
        end
      end

      context "when class with const path" do
        let(:code) do
          <<~CODE
            class Post::Comment
            end
          CODE
        end

        it "registers one class" do
          expect_class_exists("Post::Comment")
        end
      end

      context "when class in class" do
        let(:code) do
          <<~CODE
            class Post
              class Comment
              end
            end
          CODE
        end

        it "registers one class" do
          expect_class_exists("Post::Comment")
        end
      end

      context "when class in module" do
        let(:code) do
          <<~CODE
            module Post
              class Comment
              end
            end
          CODE
        end

        it "registers one class" do
          expect_class_exists("Post::Comment")
        end
      end

      context "when every const with constant path" do
        let(:code) do
          <<~CODE
            module A::B
              class C::D
                class E::F
                end
              end
            end
          CODE
        end

        it "registers one class" do
          expect_class_exists("A::B::C::D::E::F")
        end
      end

      context "when inherit" do
        let(:code) do
          <<~CODE
            class A
            end

            class B < A
            end
          CODE
        end

        it "registers all classes" do
          expect_class_exists("A")
          expect_class_exists("B")
          expect_class_inherits("B", "A")
        end
      end

      context "when inherit with const path" do
        let(:code) do
          <<~CODE
            module A
              class B
              end
            end

            class C < A::B
            end
          CODE
        end

        it "registers all classes" do
          expect_class_exists("A::B")
          expect_class_exists("C")
          expect_class_inherits("C", "A::B")
          expect_class_inherits("singleton(C)", "A::B")
        end
      end

      context "when include" do
        let(:code) do
          <<~CODE
            module A
            end

            class B
              include A
            end
          CODE
        end

        it "registers all classes" do
          expect_module_exists("A")
          expect_class_exists("B")
          expect_class_includes("B", "A")
        end
      end

      context "when include with const path" do
        let(:code) do
          <<~CODE
            module A
              class B
              end
            end

            class C
              include A::B
            end
          CODE
        end

        it "registers all classes" do
          expect_module_exists("A")
          expect_class_exists("A::B")
          expect_class_includes("C", "A::B")
        end
      end

      context "when extend" do
        let(:code) do
          <<~CODE
            module A
            end

            class B
              extend A
            end
          CODE
        end

        it "registers all classes" do
          expect_module_exists("A")
          expect_class_exists("B")
          expect_class_extends("B", "A")
        end
      end

      context "when extend with const path" do
        let(:code) do
          <<~CODE
            module A
              class B
              end
            end

            class C
              extend A::B
            end
          CODE
        end

        it "registers all classes" do
          expect_module_exists("A")
          expect_class_exists("A::B")
          expect_class_extends("C", "A::B")
        end
      end

      context "when const with assign" do
        let(:code) do
          <<~CODE
            CustomError = Class.new(StandardError)
          CODE
        end

        xit "registers one class" do
          expect_class_exists("CustomError")
        end
      end
    end

    describe "Parse module def" do
      context "when simple module" do
        let(:code) do
          <<~CODE
            module A
            end
          CODE
        end

        it "registers one module" do
          expect_module_exists("A")
        end
      end

      context "when const path" do
        let(:code) do
          <<~CODE
            module A::B
            end
          CODE
        end

        it "registers one module" do
          expect_module_exists("A::B")
        end
      end

      context "when nest module path" do
        let(:code) do
          <<~CODE
            module A
              module C
              end
            end
          CODE
        end

        it "registers one module" do
          expect_module_exists("A::C")
        end
      end

      context "when nest module path" do
        let(:code) do
          <<~CODE
            module A::B
              module C::D
              end
            end
          CODE
        end

        it "registers one module" do
          expect_module_exists("A::B::C::D")
        end
      end
    end

    describe "Parse instance method def in class" do
      let(:code) do
        <<~CODE
          class A
            def default_public_method = 1
            private def explicit_private_method = 1
            def defered_private_method = 1
            private :defered_private_method

            private

            def default_private_method = 1
            public def explicit_public_method = 1
            def defered_public_method = 1
            public :defered_public_method
          end
        CODE
      end

      it "registers method with correct visibility" do
        expect_receiver_responds("A", :public, "default_public_method")
        expect_receiver_responds("A", :public, "explicit_public_method")
        expect_receiver_responds("A", :public, "defered_public_method")

        expect_receiver_responds("A", :private, "default_private_method")
        expect_receiver_responds("A", :private, "explicit_private_method")
        expect_receiver_responds("A", :private, "defered_private_method")
      end
    end

    describe "Parse class method def in class" do
      let(:code) do
        <<~CODE
          class A
            class << self
              def default_public_method = 1
              private def explicit_private_method = 1
              def defered_private_method = 1
              private :defered_private_method

              private

              def default_private_method = 1
              public def explicit_public_method = 1
              def defered_public_method = 1
              public :defered_public_method
            end
          end
        CODE
      end

      it "registers method with correct visibility" do
        expect_receiver_responds("singleton(A)", :public, "default_public_method")
        expect_receiver_responds("singleton(A)", :public, "explicit_public_method")
        expect_receiver_responds("singleton(A)", :public, "defered_public_method")

        expect_receiver_responds("singleton(A)", :private, "default_private_method")
        expect_receiver_responds("singleton(A)", :private, "explicit_private_method")
        expect_receiver_responds("singleton(A)", :private, "defered_private_method")
      end
    end

    describe "Parse self method def in class" do
      let(:code) do
        <<~CODE
          class A
            def self.default_public_method = 1
          end
        CODE
      end

      it "registers method with correct visibility" do
        expect_receiver_responds("singleton(A)", :public, "default_public_method")
      end
    end

    describe "Parse method def in module" do
      let(:code) do
        <<~CODE
          module A
            def default_public_method = 1
            private
            public def explicit_public_method = 1
            def defered_public_method = 1
            public :defered_public_method
          end
        CODE
      end

      it "registers method with correct visibility" do
        expect_receiver_responds("A", :public, "default_public_method")
        expect_receiver_responds("A", :public, "explicit_public_method")
        expect_receiver_responds("A", :public, "defered_public_method")
      end
    end

    describe "Parse module function method def in module" do
      let(:code) do
        <<~CODE
          module A
            def defer_method = 1
            module_function :defer_method

            module_function
            def default_method = 1
          end
        CODE
      end

      it "registers method with correct visibility" do
        expect_receiver_responds("singleton(A)", :public, "default_method")
        expect_receiver_responds("singleton(A)", :public, "defer_method")
        expect_receiver_responds("A", :private, "default_method")
        expect_receiver_responds("A", :private, "defer_method")
      end
    end

    describe "Parse self method def in module" do
      let(:code) do
        <<~CODE
          module A
            def self.default_public_method = 1
          end
        CODE
      end

      it "registers method with correct visibility" do
        expect_receiver_responds("singleton(A)", :public, "default_public_method")
      end
    end
  end
end
