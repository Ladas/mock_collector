module MockCollector
  class EntityType
    include Enumerable

    attr_reader :storage, :data, :ref_id, :name, :entities_total

    delegate :collector_type,
             :class_for, :to => :storage

    # @param name [Symbol] identifier in storage
    # @param storage [MockCollector::Storage]
    # @param ref_id [Integer] specific part for uuids of
    #                         all entities of this type
    def initialize(name, storage, ref_id)
      @name = name
      @storage = storage
      @ref_id = ref_id

      @data = []

      @entities_total = ::Settings.amounts[@name.to_sym].to_i
    end

    def each
      @data.each do |entity|
        yield entity
      end
    end

    def <<(entity)
      @data << entity
    end
    alias push <<

    # TODO Starting resource_version to watch notification
    def resourceVersion
      nil
    end

    # Creates data of one type (means for 1 InventoryCollection) with amount based on YAML config
    def create_data
      @entities_total.times do |i|
        @data << entity_class.new(i, self)
      end
    end

    # To each EntityType belongs one Entity class
    def entity_class
      return @entity_class unless @entity_class.nil?

      class_name = "MockCollector::#{collector_type.to_s.classify}::Entity::#{@name.to_s.classify}"
      klass = class_name.safe_constantize

      raise "Entity class #{class_name} doesn't exists!" if klass.to_s != class_name
      @entity_class = klass
    end

    # Generated reference between entities
    #
    # @param entity_id [Integer] entity's id
    # @param dest_entity_type [Symbol] one of MockCollector::Storage.entity_types
    # @param ref [Symbol] :uid  => get UID of target entity
    #                     :name => get name of target entity
    def link(entity_id, dest_entity_type, ref: :uid)
      assert_objects_count(dest_entity_type)

      dest_entity_id = entity_id % ::Settings.amounts[dest_entity_type]

      case ref
      when :uid then @storage.entities[dest_entity_type].uid_for(dest_entity_id)
      when :name then @storage.entities[dest_entity_type].name_for(dest_entity_id)
      else raise "Link to ref #{ref} not supported (Entity: #{@name})"
      end
    end

    # Unique ID for given entity
    # 2 strategies available:
    # - uuids - UUID format, sequential, same everytime
    # - human_readable - Mixed text-number unique ID, same everytime
    def uid_for(entity_id)
      case ::Settings.uuid_strategy
      when :human_readable then human_readable_uid(entity_id)
      when :uuids then sequence_uuid(entity_id)
      else raise "Unknown UUID generating strategy: #{::Settings.uuid_strategy}. Choose from (:human_readable_uids, :sequence_uuids)"
      end
    end

    # Unique name for given entity
    # Always the same for given ID
    def name_for(entity_id)
      name = entity_class.name.to_s.split("::").last
      "mock-#{name.downcase}-#{entity_id}"
    end

    private

    # Real GUID simulation
    def sequence_uuid(entity_id)
      collector_id   = "%08x" % storage.ref_id
      entity_type_id = "%04x" % @ref_id
      ref_id         = "%020x" % entity_id

      "#{collector_id}-#{entity_type_id}-#{ref_id[0..3]}-#{ref_id[4..7]}-#{ref_id[8..19]}"
    end

    # Entity-type specific readable ID
    def human_readable_uid(entity_id)
      "#{storage.collector_type}-#{@name}-#{'%010d' % entity_id}"
    end

    def assert_objects_count(dest_entity_type)
      if ::Settings.amounts[dest_entity_type].to_i == 0
        # TODO: can be nil in the future
        raise "Nil config on #{dest_entity_type}"
      end
    end
  end
end
