module MatconClient
  class Container < Model
    self.endpoint = 'containers'

    alias_attribute :uuid, :id

    def serialize
      container_hash = super
      container_hash.merge!(slots: serialize_slots) unless attributes[:slots].nil?
      container_hash
    end

    def slots
    	@slots ||= make_slots(super)
    end

    def material_ids
    	slots.lazy.reject(&:empty?).map(&:material_id).force
    end

    def materials
      slots_to_fetch = slots.select do |slot|
        !slot.empty? && slot.material.nil?
      end

      if (!slots_to_fetch.empty?)
        rs = MatconClient::Material.where(_id: { "$in": slots_to_fetch.map(&:material_id) }).result_set

        slots_to_fetch.each do |s|
          s.material = rs.find { |material| s.material_id == material.id }
        end
      end

      slots.select { |slot| !slot.empty? }.map(&:material)
    end

    def add_to_slot(address, material)
      slot = slots.select{|s| s.address == address}.first
      slot.material_id = material.id
    end

    def self.add_to_slot(barcode, address, material)
      container = where(barcode: barcode).first
      container.add_to_slot(address, material)
    end

    def self.add_to_slots(layout)
      layout.each do |address, material|
        add_to_slot(address, material)
      end
    end

  private

    def make_slots(superslots)
      if superslots.nil?
        return nil
      else
      	return superslots.map { |s| MatconClient::Slot.new(s) }
      end
    end

    def serialize_slots
      slots.map(&:serialize)
    end
  end
end