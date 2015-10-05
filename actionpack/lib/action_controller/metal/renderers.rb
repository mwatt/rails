require 'set'

module ActionController
  # See <tt>Renderers.add</tt>
  def self.add_renderer(key, &block)
    Renderers.add(key, &block)
  end

  # See <tt>Renderers.remove</tt>
  def self.remove_renderer(key)
    Renderers.remove(key)
  end

  # See <tt>Responder#api_behavior</tt>
  #
  #   # This is the common behavior for formats associated with APIs, such as :xml and :json.
  #   def api_behavior
  #     raise MissingRenderer.new(format) unless has_renderer?
  #   end
  #
  #   # Check whether the necessary Renderer is available
  #   def has_renderer?
  #     Renderers::RENDERERS.include?(format)
  #   end
  class MissingRenderer < LoadError
    def initialize(format)
      super "No renderer defined for format: #{format}"
    end
  end

  # See <tt>Renderers.add_serializer</tt>
  def self.add_serializer(key, &block)
    Renderers.add_serializer(key, &block)
  end

  # See <tt>Renderers.remove_serializer</tt>
  def self.remove_serializer(key)
    Renderers.remove_serializer(key)
  end

  # See <tt>Renderers::MissingRenderer</tt>
  class MissingSerializer < LoadError
    def initialize(format)
      super "No serializer defined for format: #{format}"
    end
  end

  module Renderers
    extend ActiveSupport::Concern

    included do
      class_attribute :_renderers
      self._renderers = Set.new.freeze
      class_attribute :_serializers
      self._serializers = Set.new.freeze
    end

    module ClassMethods
      # TODO: Add test where this is used when controller does not
      # +include Renderers::All+.
      def use_renderers(*args)
        renderers = _renderers + args
        self._renderers = renderers.freeze
      end
      alias use_renderer use_renderers

      # See <tt>Renderers.use_renderers</tt>
      def use_serializers(*args)
        serializers = _serializers + args
        self._serializers = serializers.freeze
      end
      alias use_serializer use_serializers
    end

    # Called by +render+ in <tt>AbstractController::Renderering</tt>
    # which sets the return value as the +response_body+.
    #
    # If no renderer is found, +super+ returns control to
    # <tt>ActionView::Rendering.render_to_body</tt>.
    def render_to_body(options)
      _render_to_body_with_renderer(options) || super
    end

    def _render_to_body_with_renderer(options)
      _renderers.each do |name|
        if options.key?(name)
          _process_options(options)
          method_name = Renderers._render_with_renderer_method_name(name)
          return send(method_name, options.delete(name), options)
        end
      end
      nil
    end

    # A Set containing renderer names that correspond to available renderer procs.
    # Default values are <tt>:json</tt>, <tt>:js</tt>, <tt>:xml</tt>.
    RENDERERS = Set.new

    def self._render_with_renderer_method_name(key)
      "_render_with_renderer_#{key}"
    end

    # Adds a new renderer to call within controller actions.
    # A renderer is invoked by passing its name as an option to
    # <tt>AbstractController::Rendering#render</tt>. To create a renderer
    # pass it a name and a block. The block takes two arguments, the first
    # is the value paired with its key and the second is the remaining
    # hash of options passed to +render+.
    # A renderer must have an associated serializer.
    # See <tt>Renderers.add_serializer</tt>
    #
    # Create a csv renderer:
    #
    #   ActionController::Renderers.add_serializer :csv do |obj, options|
    #     obj.respond_to?(:to_csv) ? obj.to_csv : obj.to_s
    #   end
    #
    #   ActionController::Renderers.add :csv do |obj, options|
    #     filename = options[:filename] || 'data'
    #     str = _serialize_with_serializer_csv(obj, options)
    #     send_data str, type: Mime::Type[:CSV],
    #       disposition: "attachment; filename=#{filename}.csv"
    #   end
    #
    # Note that we used Mime::Type[:CSV] for the csv mime type as it comes with Rails.
    # For a custom renderer, you'll need to register a mime type with
    # <tt>Mime::Type.register</tt>.
    #
    # To use the csv renderer in a controller action:
    #
    #   def show
    #     @csvable = Csvable.find(params[:id])
    #     respond_to do |format|
    #       format.html
    #       format.csv { render csv: @csvable, filename: @csvable.name }
    #     end
    #   end
    # To use renderers and their mime types in more concise ways, see
    # <tt>ActionController::MimeResponds::ClassMethods.respond_to</tt>
    def self.add(key, &block)
      define_method(_render_with_renderer_method_name(key), &block)
      RENDERERS << key.to_sym
    end

    # This method is the opposite of add method.
    #
    # To remove a csv renderer:
    #
    #   ActionController::Renderers.remove(:csv)
    def self.remove(key)
      RENDERERS.delete(key.to_sym)
      method_name = _render_with_renderer_method_name(key)
      remove_method(method_name) if method_defined?(method_name)
    end

    # A Set containing serializer names that correspond to available serializer procs.
    # Default values are <tt>:json</tt>, <tt>:js</tt>, <tt>:xml</tt>.
    SERIALIZERS = Set.new

    def self._serialize_with_serializer_method_name(key)
      "_serialize_with_serializer_#{key}"
    end

    # Serializers define a method called within a renderer specific to
    # transforming the object into a mime-compatible type.
    # See <tt>Renderers.add</tt>
    #
    # The separation of serialization from rendering allows
    # composing the Renderer behavior of two methods, e.g.
    # +_render_with_renderer_json+ and +_serialize_with_serializer_json+,
    # rather than requiring one to define a method +_render_with_renderer_json+
    # in a subclass and optionally call super on it.
    #
    # A principal benefit of this approach is that it promotes serialization of an object
    # to a clearly-defined public interface, rather than requiring one to understand that
    # calling, e.g. +render json: object+ calls +_render_to_body_with_renderer(options)+
    # which calls +_render_with_renderer_#{key}+ where key is +json+, which is the method
    # defined by calling +ActionController::Renderers.add :json+.
    #
    # Example usage:
    #
    # Prior to the introduction of SERIALIZERS, customizing serialization would
    # have relied upon defining +_render_option_json+ ( pre-4.2 )
    # and +_render_with_renderer_json+ in the controller, and calling +super+ on
    # the serialized object. Now, one need only call
    # +ActionController.remove_serializer :json+ and define a new serializer with
    # +ActionController.add_serializer json do |json, options| end+. There's
    # no longer a need to add controller methods to define custom serializers.
    #
    # Pretty-printing JSON can be implemented by replacing the JSON serializer:
    #
    #   ActionController::Renderers.remove_serializer :json
    #   ActionController::Renderers.add_serializer :json do |json, options|
    #     return json if json.is_a?(String)
    #
    #     json = json.as_json(options) if json.respond_to?(:as_json)
    #     json = JSON.pretty_generate(json, options)
    #   end
    #
    # See https://groups.google.com/forum/#!topic/rubyonrails-core/K8t4-DZ_DkQ/discussion for
    # more background information.
    def self.add_serializer(key, &block)
      define_method(_serialize_with_serializer_method_name(key), &block)
      SERIALIZERS << key.to_sym
    end

    # This method is the opposite of add_serializer method.
    #
    # To remove a csv serializer:
    #
    #   ActionController.remove_serializer(:csv)
    def self.remove_serializer(key)
      SERIALIZERS.delete(key.to_sym)
      method_name = _serialize_with_serializer_method_name(key)
      remove_method(method_name) if method_defined?(method_name)
    end

    module All
      extend ActiveSupport::Concern
      include Renderers

      included do
        self._renderers = RENDERERS
        self._serializers = SERIALIZERS
      end
    end

    add_serializer :json do |json, options|
      json.kind_of?(String) ? json : json.to_json(options)
    end

    add :json do |json, options|
      json = _serialize_with_serializer_json(json, options)

      if options[:callback].present?
        if content_type.nil? || content_type == Mime::Type[:JSON]
          self.content_type = Mime::Type[:JS]
        end

        "/**/#{options[:callback]}(#{json})"
      else
        self.content_type ||= Mime::Type[:JSON]
        json
      end
    end

    add_serializer :js do |js, options|
      js.respond_to?(:to_js) ? js.to_js(options) : js
    end

    add :js do |js, options|
      self.content_type ||= Mime::Type[:JS]
      _serialize_with_serializer_js(js, options)
    end

    add_serializer :xml do |xml, options|
      xml.respond_to?(:to_xml) ? xml.to_xml(options) : xml
    end

    add :xml do |xml, options|
      self.content_type ||= Mime::Type[:XML]
      _serialize_with_serializer_xml(xml, options)
    end
  end
end
