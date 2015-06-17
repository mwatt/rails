module ActionController
  module ImplicitRender
    def send_action(method, *args)
      ret = super
      default_render unless performed?
      ret
    end

    # Renders the template corresponding to the controller action, if it exists.
    # The action name, format, and variant are all taken into account.
    # For example, the "new" action with an HTML format and variant "phone" 
    # would try to render the <tt>new.html+phone.erb</tt> template.
    #
    # If no template is found +default_missing_template_action+ is called, unless
    # a block is passed. In that case, it will override +default_missing_template_action+:
    #
    #   default_render do
    #     head 404 # No template was found
    #   end
    #
    # +args+:: passed through to render
    def default_render(*args)
      if template_exists?(action_name.to_s, _prefixes, variants: request.variant)
        render(*args)
      else
        if block_given?
          yield(*args)
        else
          default_missing_template_action(*args)
        end
      end
    end

    # Called when +default_render+ cannot find a template to render.
    # Renders `head :no_content`.
    #
    # +args+:: passed through from default_render
    def default_missing_template_action(*args)
      logger.info "No template found for #{self.class.name}\##{action_name}, rendering head :no_content" if logger
      head :no_content
    end

    def method_for_action(action_name)
      super || if template_exists?(action_name.to_s, _prefixes)
        "default_render"
      end
    end
  end
end
