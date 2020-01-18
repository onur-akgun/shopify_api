# frozen_string_literal: true
require 'graphql/client'
require 'graphql/client/http'

module ShopifyAPI
  class GraphQL
    DEFAULT_SCHEMA_LOCATION_PATH = Pathname('shopify_graphql_schemas')

    class << self
      delegate :parse, :query, to: :client

      def initialize_clients
        @_client_cache ||= {}

        Dir.glob(schema_location.join("*.json")).each do |schema_file|
          schema_file = Pathname(schema_file)
          matches = schema_file.basename.to_s.match(/^#{ShopifyAPI::ApiVersion::HANDLE_FORMAT}\.json$/)

          if matches
            api_version = matches[1]
          else
            raise "Invalid schema file name `#{schema_file}`. Does not match format of: `<version>.json`."
          end

          schema = ::GraphQL::Client.load_schema(schema_file.to_s)
          client = ::GraphQL::Client.new(schema: schema, execute: HTTPClient.new(api_version))

          @_client_cache[api_version] = client
        end
      end

      def schema_location
        @schema_location || DEFAULT_SCHEMA_LOCATION_PATH
      end

      def schema_location=(path)
        path = Pathname(path)

        if path.exist?
          @schema_location = path
        else
          raise "Schema location #{path} does not exist."
        end
      end

      def client(api_version = nil)
        @_client_cache ||= {}

        selected_api_version = api_version || ShopifyAPI::Base.api_version.handle

        if @_client_cache.size > 1 && !selected_api_version
          raise <<~MSG
            Clients for multiple API versions exist but API version was not specified.
            Either call the `client` method with an explicit API version (ie: '2020-01')
            or ensure `ShopifyAPI::Base.api_version` is set.

            Possible clients for versions: #{@_client_cache.keys.join(', ')}
          MSG
        end

        cached_client = @_client_cache[selected_api_version]

        if cached_client
          cached_client
        else
          schema_file = schema_location.join("#{selected_api_version}.json")

          if !schema_file.exist?
            raise <<~MSG
              Client for API version #{selected_api_version} does not exist because no schema file exists
              at `#{schema_file}`.

              To dump the schema file, use the `rake shopify_api:graphql:dump` task.
            MSG
          else
            puts '[WARNING] Client was not pre-initialized. Ensure `ShopifyAPI::GraphQL.initialize_clients` is called during app initialization.'
            initialize_clients
            @_client_cache[selected_api_version]
          end
        end
      end
    end

    class HTTPClient < ::GraphQL::Client::HTTP
      def initialize(api_version)
        @api_version = api_version
      end

      def headers(_context)
        ShopifyAPI::Base.headers
      end

      def uri
        ShopifyAPI::Base.site.dup.tap do |uri|
          uri.path = "#{ShopifyAPI::ApiVersion::API_PREFIX}#{@api_version}/#{ShopifyAPI::ApiVersion::GRAPHQL_PATH}"
        end
      end
    end
  end
end
