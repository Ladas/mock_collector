require "more_core_extensions/core_ext/string/iec60027_2"
require "more_core_extensions/core_ext/string/decimal_suffix"

require "topological_inventory/collector/mock/parser"

module TopologicalInventory
  module Collector
    module Mock
      module Openshift
        class Parser < ::TopologicalInventory::Collector::Mock::Parser
          require "topological_inventory/collector/mock/openshift/parser/image"
          require "topological_inventory/collector/mock/openshift/parser/pod"
          require "topological_inventory/collector/mock/openshift/parser/namespace"
          require "topological_inventory/collector/mock/openshift/parser/node"
          require "topological_inventory/collector/mock/openshift/parser/template"
          require "topological_inventory/collector/mock/openshift/parser/cluster_service_class"
          require "topological_inventory/collector/mock/openshift/parser/cluster_service_plan"
          require "topological_inventory/collector/mock/openshift/parser/service_instance"

          include TopologicalInventory::Collector::Mock::Openshift::Parser::Image
          include TopologicalInventory::Collector::Mock::Openshift::Parser::Pod
          include TopologicalInventory::Collector::Mock::Openshift::Parser::Namespace
          include TopologicalInventory::Collector::Mock::Openshift::Parser::Node
          include TopologicalInventory::Collector::Mock::Openshift::Parser::Template
          include TopologicalInventory::Collector::Mock::Openshift::Parser::ClusterServiceClass
          include TopologicalInventory::Collector::Mock::Openshift::Parser::ClusterServicePlan
          include TopologicalInventory::Collector::Mock::Openshift::Parser::ServiceInstance

          def initialize
            super

            # TODO: merge with Server
            entity_types = %i(containers container_groups container_nodes container_projects container_images
                          container_templates service_instances service_offerings service_plans
                          container_group_tags container_node_tags container_project_tags container_image_tags
                          container_template_tags service_offering_tags service_offering_icons)

            self.collections = entity_types.each_with_object({}).each do |entity_type, collections|
              collections[entity_type] = TopologicalInventoryIngressApiClient::InventoryCollection.new(:name => entity_type, :data => [])
            end
          end

          private

          def parse_base_item(entity)
            {
              :name               => entity.metadata.name,
              :resource_version   => entity.metadata.resourceVersion,
              :resource_timestamp => resource_timestamp,
              :source_created_at  => entity.metadata.creationTimestamp,
              :source_ref         => entity.metadata.uid,
            }
          end

          def archive_entity(inventory_object, entity)
            source_deleted_at                  = entity.metadata&.deletionTimestamp || Time.now.utc
            inventory_object.source_deleted_at = source_deleted_at
          end

          def lazy_find_namespace(name)
            return if name.nil?

            TopologicalInventoryIngressApiClient::InventoryObjectLazy.new(
              :inventory_collection_name => :container_projects,
              :reference                 => {:name => name},
              :ref                       => :by_name,
            )
          end

          def lazy_find_node(name)
            return if name.nil?

            TopologicalInventoryIngressApiClient::InventoryObjectLazy.new(
              :inventory_collection_name => :container_nodes,
              :reference                 => {:name => name},
              :ref                       => :by_name,
            )
          end

          def parse_quantity(quantity)
            return if quantity.nil?

            begin
              quantity.iec_60027_2_to_i
            rescue
              quantity.decimal_si_to_f
            end
          end
        end
      end
    end
  end
end
