#frozen_string_literal: true

require_relative "../../../../support/openai_completions_inference_stubs"

RSpec.describe DiscourseAi::AiBot::Commands::TagsCommand do
  describe "#process" do
    it "can generate correct info" do
      SiteSetting.tagging_enabled = true

      Fabricate(:tag, name: "america", public_topic_count: 100)
      Fabricate(:tag, name: "not_here", public_topic_count: 0)

      info = DiscourseAi::AiBot::Commands::TagsCommand.new(nil, nil).process(nil)

      expect(info).to include("america")
      expect(info).not_to include("not_here")
    end
  end
end
