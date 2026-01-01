# typed: strict
# frozen_string_literal: true

module Garmin
  class Connection
    extend T::Sig

    sig { returns(String) }
    def self.default_data_path
      File.expand_path('~/Library/Application Support/garmin')
    end

    sig { returns(String) }
    def self.default_db_path
      File.join(default_data_path, 'garmin.duckdb')
    end

    sig { returns(String) }
    def self.default_path
      env_data_path = ENV['GARMIN_DATA_PATH']
      return env_data_path if env_data_path && !env_data_path.empty?

      env_db_path = ENV['GARMIN_DB_PATH']
      return env_db_path if env_db_path && !env_db_path.empty?

      default_data_path
    end

    sig { params(path: String).returns(T::Boolean) }
    def self.parquet_available?(path)
      return false unless File.directory?(path)

      %w[activities daily_health performance_metrics].any? do |dir|
        Dir.glob(File.join(path, dir, '*.parquet')).any?
      end
    end

    sig { params(path: String, read_only: T::Boolean).void }
    def initialize(path = self.class.default_path, read_only: true)
      @path = path
      @read_only = read_only
      @connected = T.let(false, T::Boolean)
      @mode = T.let(nil, T.nilable(Symbol))
      @data_path = T.let(nil, T.nilable(String))
      @db = T.let(nil, T.nilable(DuckDB::Database))
      @conn = T.let(nil, T.nilable(DuckDB::Connection))

      connect!
    end

    sig { returns(T::Boolean) }
    def connected?
      @connected
    end

    sig { returns(T::Boolean) }
    def parquet?
      @mode == :parquet
    end

    sig { returns(T::Boolean) }
    def db?
      @mode == :db
    end

    sig { params(dataset: String).returns(T::Boolean) }
    def dataset_available?(dataset)
      return true if db?
      return false unless @data_path

      path = dataset_path(@data_path, dataset)
      if dataset == 'profiles'
        File.exist?(path)
      else
        Dir.glob(path).any?
      end
    end

    sig { params(sql: String).returns(T::Array[T::Hash[String, T.untyped]]) }
    def query(sql)
      raise ConnectionError, 'Not connected' unless @conn

      result = @conn.query(sql)
      column_names = result.columns.map(&:name)
      rows = []

      result.each do |row|
        hash = {}
        column_names.each_with_index do |col_name, i|
          hash[col_name] = row[i]
        end
        rows << hash
      end

      rows
    end

    sig { params(dataset: String).returns(String) }
    def table_sql(dataset)
      return dataset if db?

      base = T.must(@data_path)
      path = dataset_path(base, dataset)
      "'#{path}'"
    end

    sig { params(value: String).returns(String) }
    def quote_string(value)
      value.gsub("'", "''")
    end

    sig { params(sql: String).void }
    def execute(sql)
      raise ConnectionError, 'Not connected' unless @conn

      @conn.query(sql)
    end

    sig { void }
    def close
      @conn&.close if @conn.respond_to?(:close)
      @db&.close if @db.respond_to?(:close)
      @conn = nil
      @db = nil
      @connected = false
    end

    private

    sig { void }
    def connect!
      if @path == ':memory:'
        @db = DuckDB::Database.open
        @conn = @db.connect
        @connected = true
        @mode = :db
      elsif File.directory?(@path)
        @db = DuckDB::Database.open
        @conn = @db.connect
        @connected = true
        @mode = :parquet
        @data_path = @path
      else
        unless File.exist?(@path)
          raise ConnectionError, "Database not found: #{@path}"
        end

        config = DuckDB::Config.new
        config['access_mode'] = 'READ_ONLY' if @read_only
        @db = DuckDB::Database.open(@path, config)
        @conn = @db.connect
        @connected = true
        @mode = :db
      end
    rescue DuckDB::Error => e
      raise ConnectionError, "Failed to connect: #{e.message}"
    end

    sig { params(base: String, dataset: String).returns(String) }
    def dataset_path(base, dataset)
      if dataset == 'profiles'
        File.join(base, 'profiles.parquet')
      else
        File.join(base, dataset, '*.parquet')
      end
    end
  end
end
