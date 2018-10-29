require "openshift/mock/configuration"
require "openshift/mock/entities"
require "openshift/mock/entity/namespace"
require "openshift/mock/entity/pod"
require "openshift/mock/entity/node"
require "openshift/mock/entity/template"
require "openshift/mock/entity/cluster_service_class"
require "openshift/mock/entity/cluster_service_plan"
require "openshift/mock/entity/service_instance"

module Openshift
  module Mock
    class Connection
      def initialize(api_version = "v1")
        @api_version = api_version
        @config = Openshift::Mock::Configuration.instance

        @entities = {}
      end

      def create_entities(entity_type)
        @entities[entity_type] = Openshift::Mock::Entities.new
        model_name = entity_type.classify
        klass = "Openshift::Mock::Entity::#{model_name}".safe_constantize
        raise "Unknown entity #{model_name}" if klass.nil?

        raise "Entity type #{entity_type} not configured!" if @config.objects_count[entity_type.to_sym].nil?
        @config.objects_count[entity_type.to_sym].to_i.times do |i|
          @entities[entity_type] << klass.new(i)
        end
        @entities[entity_type]
      end

      def method_missing(method_name, *arguments, &block)
        if method_name.to_s.start_with?('get_')
          create_entities(method_name.to_s.gsub("get_", '').singularize)
        elsif method_name.to_s.start_with?('watch_')
          nil
        else
          super
        end
      end

      def respond_to_missing?(method_name, _include_private = false)
        method_name.to_s.start_with?("get_") || method_name.to_s.start_with?("watch_")
      end
    end
  end
end
