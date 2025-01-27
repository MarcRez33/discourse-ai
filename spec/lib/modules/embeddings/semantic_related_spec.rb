# frozen_string_literal: true

require "rails_helper"

describe DiscourseAi::Embeddings::SemanticRelated do
  fab!(:target) { Fabricate(:topic) }
  fab!(:normal_topic_1) { Fabricate(:topic) }
  fab!(:normal_topic_2) { Fabricate(:topic) }
  fab!(:normal_topic_3) { Fabricate(:topic) }
  fab!(:unlisted_topic) { Fabricate(:topic, visible: false) }
  fab!(:private_topic) { Fabricate(:private_message_topic) }
  fab!(:secured_category) { Fabricate(:category, read_restricted: true) }
  fab!(:secured_category_topic) { Fabricate(:topic, category: secured_category) }
  fab!(:closed_topic) { Fabricate(:topic, closed: true) }

  before { SiteSetting.ai_embeddings_semantic_related_topics_enabled = true }

  describe "#candidates_for" do
    context "when embeddings do not exist" do
      let (:topic) do
        topic = Fabricate(:topic)
        described_class.clear_cache_for(target)
        topic
      end

      it "queues job only once per 15 minutes" do
        # sadly we need to mock a DB connection to return nothing
        DiscourseAi::Embeddings::Topic
          .any_instance
          .expects(:query_symmetric_embeddings)
          .returns([])
          .twice

        results = nil

        expect_enqueued_with(job: :generate_embeddings, args: { topic_id: topic.id }) do
          results = described_class.candidates_for(topic).to_a
        end

        expect(results).to eq([])

        expect_not_enqueued_with(job: :generate_embeddings, args: { topic_id: topic.id }) do
          results = described_class.candidates_for(topic).to_a
        end

        expect(results).to eq([])
      end
    end
    context "when embeddings exist" do
      before do
        Discourse.cache.clear
        DiscourseAi::Embeddings::Topic
          .any_instance
          .expects(:symmetric_semantic_search)
          .returns(Topic.unscoped.order(id: :desc).limit(100).pluck(:id))
      end

      after { Discourse.cache.clear }

      it "returns the related topics without non public topics" do
        results = described_class.candidates_for(target).to_a
        expect(results).to include(normal_topic_1)
        expect(results).to include(normal_topic_2)
        expect(results).to include(normal_topic_3)
        expect(results).to include(closed_topic)
        expect(results).to_not include(target)
        expect(results).to_not include(unlisted_topic)
        expect(results).to_not include(private_topic)
        expect(results).to_not include(secured_category_topic)
      end

      context "when ai_embeddings_semantic_related_include_closed_topics is false" do
        before { SiteSetting.ai_embeddings_semantic_related_include_closed_topics = false }
        it "do not return closed topics" do
          results = described_class.candidates_for(target).to_a
          expect(results).to_not include(closed_topic)
        end
      end
    end
  end
end
