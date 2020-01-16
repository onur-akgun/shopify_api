if defined?(Rails)
  rake_tasks do
    namespace :shopify_api do
      desc "foo"
      task :dump_graphql_schemas => :environment do
        GemFresh::Reporter.new.report
      end
    end

    # load "tasks/metrics.rake"
  end
end

