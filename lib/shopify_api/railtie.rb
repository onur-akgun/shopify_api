# frozen_string_literal: true

require 'rails/railtie'

module ShopifyAPI
  class Railtie < Rails::Railtie
    initializer 'shopify_api.initialize_graphql_clients' do |app|
      ShopifyAPI::GraphQL.schema_location = app.root.join('db', ShopifyAPI::GraphQL.schema_location)
      ShopifyAPI::GraphQL.initialize_clients
    end

    rake_tasks do
      load 'shopify_api/tasks/graphql.rake'
    end
  end
end
