# frozen_string_literal: true

# name: discourse-ai
# about: Enables AI modules features in Discourse
# version: 0.0.1
# authors: Discourse
# url: https://meta.discourse.org/t/discourse-ai/259214
# required_version: 2.7.0

gem "tokenizers", "0.3.2", platform: RUBY_PLATFORM
gem "tiktoken_ruby", "0.0.5", platform: RUBY_PLATFORM

enabled_site_setting :discourse_ai_enabled

register_asset "stylesheets/modules/ai-helper/common/ai-helper.scss"

register_asset "stylesheets/modules/summarization/common/summarization.scss"
register_asset "stylesheets/modules/summarization/desktop/summarization.scss", :desktop
register_asset "stylesheets/modules/summarization/mobile/summarization.scss", :mobile

register_asset "stylesheets/modules/ai-bot/common/bot-replies.scss"

module ::DiscourseAi
  PLUGIN_NAME = "discourse-ai"
end

require_relative "lib/discourse_ai/engine"

after_initialize do
  require_relative "lib/shared/inference/discourse_classifier"
  require_relative "lib/shared/inference/discourse_reranker"
  require_relative "lib/shared/inference/openai_completions"
  require_relative "lib/shared/inference/openai_embeddings"
  require_relative "lib/shared/inference/anthropic_completions"
  require_relative "lib/shared/inference/stability_generator"

  require_relative "lib/shared/classificator"
  require_relative "lib/shared/post_classificator"
  require_relative "lib/shared/chat_message_classificator"

  require_relative "lib/shared/tokenizer/tokenizer"

  require_relative "lib/shared/database/connection"

  require_relative "lib/modules/nsfw/entry_point"
  require_relative "lib/modules/toxicity/entry_point"
  require_relative "lib/modules/sentiment/entry_point"
  require_relative "lib/modules/ai_helper/entry_point"
  require_relative "lib/modules/embeddings/entry_point"
  require_relative "lib/modules/summarization/entry_point"
  require_relative "lib/modules/ai_bot/entry_point"

  [
    DiscourseAi::Embeddings::EntryPoint.new,
    DiscourseAi::NSFW::EntryPoint.new,
    DiscourseAi::Toxicity::EntryPoint.new,
    DiscourseAi::Sentiment::EntryPoint.new,
    DiscourseAi::AiHelper::EntryPoint.new,
    DiscourseAi::Summarization::EntryPoint.new,
    DiscourseAi::AiBot::EntryPoint.new,
  ].each do |a_module|
    a_module.load_files
    a_module.inject_into(self)
  end

  register_reviewable_type ReviewableAiChatMessage
  register_reviewable_type ReviewableAiPost

  on(:reviewable_transitioned_to) do |new_status, reviewable|
    ModelAccuracy.adjust_model_accuracy(new_status, reviewable)
  end
end
