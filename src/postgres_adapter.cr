require "./version"

require "pg"

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

    getter connection, table_name, primary_field, fields

    def initialize(@table_name, @primary_field, @fields, register = true)
      @connection = PG.connect(pg_url)
      self.class.register(self)
    end

    def create(fields)
      field_names = self.fields.select { |x| x != primary_field }
      field_refs = (1...self.fields.size).map { |x| "$#{x}" }

      query = "INSERT INTO #{table_name} (#{field_names.join(", ")}) VALUES (#{field_refs.join(", ")}) RETURNING #{primary_field}"

      values = [] of PG::PGValue
      field_names.each do |name|
        if fields.has_key?(name) && !fields[name].null?
          value = fields[name].not_null!
          if value.is_a?(Int8) || value.is_a?(Int16)
            values << value.to_i32
          else
            values << value as PG::PGValue
          end
        else
          values << nil
        end
      end

      result = connection.exec(query, values)
      result.rows[0][0]
    end

    def get(id)
      query = "SELECT #{fields.join(", ")} FROM #{table_name} WHERE #{primary_field} = $1"
      result = connection.exec(query, [id])

      return nil if result.rows.size == 0

      extract_fields(result.rows[0])
    end

    def all
      query = "SELECT #{fields.join(", ")} FROM #{table_name}"
      result = connection.exec(query)
      extract_rows(result.rows)
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

    def extract_fields(row)
      fields = {} of String => ActiveRecord::SupportedType

      self.fields.each_with_index do |name, index|
        value = row[index]
        if value.is_a?(ActiveRecord::SupportedType)
          fields[name] = value
        elsif !value.is_a?(Nil)
          puts "Encountered unsupported type: #{value.class}, of type: #{typeof(value)}"
        end
      end

      fields
    end

    def extract_rows(rows)
      rows.map { |row| extract_fields(row) }
    end

    def self._reset_do_this_only_in_specs_78367c96affaacd7
      adapters.each &._reset_do_this_only_in_specs_78367c96affaacd7
    end

    def _reset_do_this_only_in_specs_78367c96affaacd7
      connection.exec("DELETE FROM #{table_name}")
    end

    def pg_url
      ENV["PG_URL"]? || "postgres://#{pg_user}:#{pg_pass}@#{pg_host}:#{pg_port}/#{pg_database}?sslmode=#{pg_ssl_mode}"
    end

    def pg_user
      ENV["PG_USER"]? || "crystal_pg"
    end

    def pg_pass
      ENV["PG_PASS"]? || "crystal_pg"
    end

    def pg_host
      ENV["PG_HOST"]? || "127.0.0.1"
    end

    def pg_port
      ENV["PG_PORT"]? || "5432"
    end

    def pg_database
      ENV["PG_DATABASE"]? || "crystal_pg_test"
    end

    def pg_ssl_mode
      ENV["PG_SSL_MODE"]? || "disable"
    end
  end
end
