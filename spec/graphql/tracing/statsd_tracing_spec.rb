# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::StatsdTracing do
  module MockStatsd
    class << self
      def time(key)
        self.timings << key
        yield
      end

      def timings
        @timings
      end

      def clear
        @timings = []
      end
    end
  end

  class StatsdTestSchema < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      field :int, Integer, null: false

      def int
        1
      end
    end

    query(Query)

    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
    use GraphQL::Tracing::StatsdTracing, statsd: MockStatsd
  end

  before do
    MockStatsd.clear
  end

  it "gathers timings" do
    StatsdTestSchema.execute("query X { int }")
    expected_timings = [
      "graphql.execute_multiplex",
      "graphql.analyze_multiplex",
      "graphql.lex",
      "graphql.parse",
      "graphql.validate",
      "graphql.analyze_query",
      "graphql.execute_query",
      "graphql.authorized.Query",
      "graphql.execute_query_lazy"
    ]
    assert_equal expected_timings, MockStatsd.timings
  end
end
