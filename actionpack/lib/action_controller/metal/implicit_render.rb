module ActionController
  module ImplicitRender
    def send_action(method, *args)
      ret = super
      return ret if performed?

      if template_exists?(method, _prefixes, variants: request.variant)
        default_render
      else
        logger.info "No template found for #{self.class.name}#{action_name}, rendering head :no_content"
        head :no_content
      end
    end

    def default_render(*args)
      render(*args)
    end

    def method_for_action(action_name)
      super || if template_exists?(action_name.to_s, _prefixes)
        "default_render"
      end
    end
  end
end
