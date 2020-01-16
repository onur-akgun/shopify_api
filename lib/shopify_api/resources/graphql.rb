# frozen_string_literal: true
require 'graphql/client'
require 'graphql/client/http'

module ShopifyAPI
  class GraphQL
    class << self
      include ThreadsafeAttributes

      delegate :parse, :query, to: :client

      threadsafe_attribute(:_schema_file_path, :_client)

      def schema_file_path
        if _schema_file_path_defined?
          _schema_file_path
        elsif superclass != Object && superclass.schema_file_path
          superclass.schema_file_path
        end
      end

      def schema_file_path=(api_version, schema_file_path)
        if File.exists?(schema_file_path)
          self._schema_file_path = schema_file_path
        else
          raise "Schema file #{schema_file_path} does not exist."
        end
      end

      def client
        if _client_defined?
          _client
        elsif superclass != Object && superclass.client
          superclass.client
          else
          self._client ||= ::GraphQL::Client.new(schema: schema, execute: HTTPClient.new)
        end
      end

      def schema
        if _schema_defined?
          _schema
        elsif superclass != Object && superclass.schema
          superclass.schema
        else
          self._schema ||= ::GraphQL::Client.load_schema(schema_file_path) end
      end
    end

    class HTTPClient < ::GraphQL::Client::HTTP
      # avoid initializing @uri
      def initialize; end

      def headers(_context)
        ShopifyAPI::Base.headers
      end

      def uri
        ShopifyAPI::Base.site.dup.tap do |uri|
          uri.path = Base.api_version.construct_graphql_path
        end
      end
    end
  end
end
