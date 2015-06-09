module ActionController
  module ImplicitRender
    def send_action(method, *args)
      ret = super
      default_render unless performed?
      ret
    end

    # Perform the default rendering for the given action and variant.
    # Essentially calls +render+ with +args+ if there is an appropriate template for the request.
    #
    # If there is no appropriate template, and no block is given, defers to
    # +default_missing_template_action+.  Otherwise, executes the block.
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

    # When there is no template for a given action, returns an empty HEAD.  To override,
    # pass a block to +default_render+
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
