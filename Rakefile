require 'rake'
require "bundler/gem_tasks"
require 'pry'
require 'pry-byebug'

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.warning = false
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "shopify_api #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :docker do
  cmd = "docker-compose up -d && docker exec -i -t shopify_api bash"
  exec(cmd, err: File::NULL)
end

require 'shopify_api'

task :graphql_client do
  # call 1: first shop, api version that we have a dump file for

  ShopifyAPI::Base.site = "https"
  ShopifyAPI::Base.api_version = '2019-04'
  ShopifyAPI::GraphQL.schema_location = 'db/shopify_api/graphql_schemas/'

  # ShopifyAPI::GraphQL.initialize_client('2019-04') # TODO let them manually pick one?
  ShopifyAPI::GraphQL.initialize_clients

  SHOP_NAME_QUERY = ShopifyAPI::GraphQL.client.parse <<-'GRAPHQL'
    {
      shop {
        name
      }
    }
  GRAPHQL

  result = ShopifyAPI::GraphQL.client.query(SHOP_NAME_QUERY)
  puts result.to_h

  # call 2: changing shop

  ShopifyAPI::Base.site = 'https'
  result = ShopifyAPI::GraphQL.client.query(SHOP_NAME_QUERY)
  puts result.to_h

  binding.pry
end

task :fetch_and_dump_schema, [:token, :api_version] do |task, args|
  puts args
  # bui
  ShopifyAPI::Base.site = "https"
  ShopifyAPI::Base.api_version = api_version
  INTROSPECTION_QUERY = ShopifyAPI::GraphQL.client.parse(GraphQL::Introspection::INTROSPECTION_QUERY)
  result = ShopifyAPI::GraphQL.client.query(INTROSPECTION_QUERY)
  File.write(ShopifyAPI::GraphQL.schema_location.join("#{api_version}.json"))
end

# task :work, [:option, :foo, :bar] do |task, args|
#   puts "work", args
# end
