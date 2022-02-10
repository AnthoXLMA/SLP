class NonPersistent
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::Serialization
  extend ActiveModel::Naming

  class Error < StandardError
  end

  module Type
    class JSON < ActiveModel::Type::Value
      def type
        :json
      end

      private

      def cast_value(value)
        value.instance_of?(String) ? ::JSON.parse(value) : value
      end
    end

    class Symbol < ActiveModel::Type::Value
      def type
        :symbol
      end

      private

      def cast_value(value)
        value.instance_of?(String) || value.instance_of?(Symbol) ? value.to_s : nil
      end
    end
  end

  def initialize(attributes = {})
    attributes = self.class.columns.map { |c| [c, nil] }.to_h.merge(attributes)
    attributes.symbolize_keys.each do |name, value|
      send("#{name}=", value)
    end
  end

  def self.column(name, sql_type = :string, default = nil, null = true)
    @@columns ||= {}
    @@columns[self.name] ||= []
    @@columns[self.name] << name.to_sym
    attr_reader name

    caster = case sql_type
             when :integer
               ActiveModel::Type::Integer
             when :string
               ActiveModel::Type::String
             when :float
               ActiveModel::Type::Float
             when :datetime
               ActiveModel::Type::DateTime
             when :boolean
               ActiveModel::Type::Boolean
             when :json
               TableLess::Type::JSON
             when :symbol
               TableLess::Type::Symbol
             when :none
               ActiveModel::Type::Value
             else
               raise TableLess::Error, 'Type unknown'
             end
    define_column(name, caster, default, null)
  end

  def self.define_column(name, caster, default = nil, _null = true)
    define_method "#{name}=" do |value|
      casted_value = caster.new.cast(value || default)
      set_attribute_after_cast(name, casted_value)
    end
  end

  def self.columns
    @@columns[name]
  end

  def set_attribute_after_cast(name, casted_value)
    instance_variable_set("@#{name}", casted_value)
  end

  def attributes
    kv = self.class.columns.map { |key| [key, send(key)] }
    kv.to_h
  end

  def persisted?
    false
  end
end
