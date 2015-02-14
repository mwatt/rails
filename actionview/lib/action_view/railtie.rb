require "action_view"
require "rails"

module ActionView
  # = Action View Railtie
  class Railtie < Rails::Railtie # :nodoc:
    config.action_view = ActiveSupport::OrderedOptions.new
    config.action_view.embed_authenticity_token_in_remote_forms = false

    config.eager_load_namespaces << ActionView

    initializer "action_view.embed_authenticity_token_in_remote_forms" do |app|
      ActiveSupport.on_load(:action_view) do
        ActionView::Helpers::FormTagHelper.embed_authenticity_token_in_remote_forms =
          app.config.action_view.delete(:embed_authenticity_token_in_remote_forms)
      end
    end

    initializer "action_view.logger" do
      ActiveSupport.on_load(:action_view) { self.logger ||= Rails.logger }
    end

    initializer "action_view.set_configs" do |app|
      ActiveSupport.on_load(:action_view) do
        app.config.action_view.each do |k,v|
          send "#{k}=", v
        end
      end
    end

    initializer "action_view.caching" do |app|
      ActiveSupport.on_load(:action_view) do
        if app.config.action_view.cache_template_loading.nil?
          ActionView::Resolver.caching = app.config.cache_classes
        end
      end
    end

    initializer "action_view.collection_caching" do |app|
      ActiveSupport.on_load(:action_controller) do
        PartialRenderer.collection_cache = app.config.action_controller.cache_store
      end
    end

    initializer "action_view.setup_action_pack" do |app|
      ActiveSupport.on_load(:action_controller) do
        ActionView::RoutingUrlFor.include(ActionDispatch::Routing::UrlFor)
      end
    end

    initializer "cache_templates" do
      ActiveSupport.on_load(:action_controller) do
        if Rails.env.production? && app.config.eager_load_templates
          ActionView::TemplateEagerLoader.new(_view_paths).cache_templates
        end
      end
    end

    rake_tasks do
      load "action_view/tasks/dependencies.rake"
    end
  end
end
