# frozen_string_literal: true
require 'graphql/client'
require 'graphql/client/http'

module ShopifyAPI
  class GraphQL
    DEFAULT_SCHEMA_LOCATION_PATH = 'db/shopify_api/graphql_schemas/'

    class << self
      delegate :parse, :query, to: :client

      attr_reader :schema_location

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

          puts "building #{schema_file} client"
          @_client_cache[api_version] = client
        end
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
        # TODO: raise if they haven't set `api_version` param or `ShopifyAPI::Base.api_version`, and there's more than
        # one in the cache

        selected_api_version = api_version || ShopifyAPI::Base.api_version.handle
        cached_client = @_client_cache[selected_api_version]

        if cached_client
          cached_client
        else
          # TODO: cache miss: call remotely, or force devs to dump schema .json ahead of time?
          raise "Client for API version #{selected_api_version} not configured"
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

      def execute(*args)
        puts uri.request_uri
        super
      end

      def uri
        ShopifyAPI::Base.site.dup.tap do |uri|
          uri.path = "#{ShopifyAPI::ApiVersion::API_PREFIX}#{@api_version}/#{ShopifyAPI::ApiVersion::GRAPHQL_PATH}"
        end
      end
    end
  end
end
