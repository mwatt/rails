require 'optparse'

desc 'Print out all defined routes in match order, with names. Target specific controller with CONTROLLER=x.'
task routes: :environment do
  all_routes = Rails.application.routes.routes
  require 'action_dispatch/routing/inspector'
  inspector = ActionDispatch::Routing::RoutesInspector.new(all_routes)
  options = { controller: ENV['CONTROLLER'] }

  OptionParser.new do |opts|
    opts.banner = "Usage: rake routes [options]"
    opts.on("-c", "--controller [PATTERN]", String) do |pattern|
      options[:controller] = pattern
    end
    opts.on("-g", "--grep [PATTERN]", String) do |pattern|
      options[:pattern] = pattern
    end
  end.parse!(ARGV.reject { |x| x == "routes" })

  puts inspector.format(ActionDispatch::Routing::ConsoleFormatter.new, options)

  # exit at the end will make sure that the extra arguments won't be interpreted as Rake task.
  exit 0
end
