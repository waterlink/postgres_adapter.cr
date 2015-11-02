require "./version"

require "active_record"
require "active_record/adapter"

module PostgresAdapter
  class Adapter < ActiveRecord::Adapter
    def self.build(table_name, primary_field, fields, register = true)
      new(table_name, primary_field, fields, register)
    end

    def self.register(adapter)
      adapters << adapter
    end

    def self.adapters
      (@@_adapters ||= [] of self).not_nil!
    end

    getter table_name, primary_field, fields

    def initialize(@table_name, @primary_field, @fields, register = true)
      self.class.register(self)
    end

    def create(fields)
      0
    end

    def get(id)
      nil
    end

    def all
      [] of Hash(String, ActiveRecord::SupportedType)
    end

    def where(query_hash : Hash)
      all
    end

    def where(query : ActiveRecord::Query)
      all
    end

    def update(id, fields)
    end

    def delete(id)
    end

    def self._reset_do_this_only_in_specs_78367c96affaacd7
      adapters.each &._reset_do_this_only_in_specs_78367c96affaacd7
    end

    def _reset_do_this_only_in_specs_78367c96affaacd7
    end
  end
end
