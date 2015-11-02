require "./version"

require "pg"

require "active_record"
require "active_record/adapter"
require "active_record/sql/query_generator"

module PostgresAdapter
  class QueryGenerator < ::ActiveRecord::Sql::QueryGenerator
    def _generate(query : ::ActiveRecord::SupportedType, param_count = 0)
      param_count += 1
      ::ActiveRecord::Sql::Query.new("$#{param_count}", { "#{param_count}" => query })
    end
  end

  class Adapter < ActiveRecord::Adapter
    include ActiveRecord::CriteriaHelper

    query_generator QueryGenerator.new

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
      q = nil

      query_hash.each do |key, value|
        if q
          q = q.& criteria(key) == value
        else
          q = criteria(key) == value
        end
      end

      where(q)
    end

    def where(query : Nil)
      [] of ActiveRecord::Fields
    end

    def where(query : ActiveRecord::Query)
      q = self.class.generate_query(query).not_nil!
      _where(q.query, q.params)
    end

    def _where(query, params)
      pg_query = "SELECT #{fields.join(", ")} FROM #{table_name} WHERE #{query}"
      params = pgify_params(params)

      result = connection.exec(pg_query, params)
      extract_rows(result.rows)
    end

    def pgify_params(params)
      (1..params.size).map do |key|
        params["#{key}"]
      end
    end

    def update(id, fields)
      fields.delete(primary_field)

      expressions = fields.keys.each_with_index(1).to_a.map { |x| "#{x[0]} = $#{x[1]}" }
      query = "UPDATE #{table_name} SET #{expressions.join(", ")} WHERE #{primary_field} = $#{expressions.size + 1}"
      params = fields.values + [id]

      connection.exec(query, params)
    end

    def delete(id)
      query = "DELETE FROM #{table_name} WHERE #{primary_field} = $1"
      connection.exec(query, [id])
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

  ActiveRecord::Registry.register_adapter("postgres", Adapter)
end
