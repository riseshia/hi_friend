# frozen_string_literal: true

module HiFriend::Core
  describe GlobalEnv do
    let(:global_env) { GlobalEnv.load! }

    describe "#consts" do
      it "returns an array" do
        expect(global_env.consts).to be_an_instance_of(Array)
      end
    end

    describe "#methods" do
      it "returns an array" do
        expect(global_env.methods).to be_an_instance_of(Array)
      end
    end
  end
end
