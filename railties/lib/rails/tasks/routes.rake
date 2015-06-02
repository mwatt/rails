require 'optparse'

desc 'Print out all defined routes in match order, with names. Target specific controller with CONTROLLER=x.'
task routes: :environment do
  all_routes = Rails.application.routes.routes
  require 'action_dispatch/routing/inspector'
  inspector = ActionDispatch::Routing::RoutesInspector.new(all_routes)
  options = { filter: ENV['CONTROLLER'] }

  OptionParser.new do |opts|
    opts.banner = "Usage: rake routes [options]"
    opts.on("-g", "--grep PATTERN", String) do |pattern|
      options[:pattern] = pattern
    end
  end.parse!(ARGV.reject { |x| x == "routes" })

  puts inspector.format(ActionDispatch::Routing::ConsoleFormatter.new, options)
  exit 0
end
