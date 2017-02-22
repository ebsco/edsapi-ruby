require 'json'

module JSONable
  module ClassMethods
    attr_accessor :attributes

    def attr_accessor(*attrs)
      self.attributes = Array attrs
      super
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def as_json
    serialized = Hash.new
    self.class.attributes.each do |attribute|
      serialized[attribute] = self.public_send attribute
    end
    serialized
  end

  def to_json(*a)
    as_json.to_json *a
  end
end