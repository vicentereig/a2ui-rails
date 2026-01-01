# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Garmin::Connection do
  describe '.default_data_path' do
    it 'returns the default Garmin CLI data directory' do
      path = described_class.default_data_path
      expect(path).to include('Application Support/garmin')
    end
  end

  describe '.default_db_path' do
    it 'returns the legacy Garmin CLI database path' do
      path = described_class.default_db_path
      expect(path).to include('garmin.duckdb')
      expect(path).to include('Application Support/garmin')
    end
  end

  describe '#initialize' do
    context 'with default path' do
      it 'connects to the default Garmin database' do
        path = described_class.default_path
        skip 'Requires garmin-cli data' unless File.exist?(path) || File.directory?(path)

        connection = described_class.new(path)
        expect(connection).to be_connected
      end
    end

    context 'with custom path' do
      it 'connects to the specified database' do
        # Create an in-memory database for testing
        connection = described_class.new(':memory:')
        expect(connection).to be_connected
      end
    end

    context 'with invalid path' do
      it 'raises an error for non-existent path' do
        expect {
          described_class.new('/nonexistent/path/garmin.duckdb')
        }.to raise_error(Garmin::ConnectionError)
      end
    end
  end

  describe '#query' do
    let(:connection) { described_class.new(':memory:') }

    it 'executes SQL queries and returns results' do
      result = connection.query('SELECT 1 + 1 AS sum')
      expect(result.first['sum']).to eq(2)
    end

    it 'returns empty array for no results' do
      connection.execute('CREATE TABLE test (id INTEGER)')
      result = connection.query('SELECT * FROM test')
      expect(result).to eq([])
    end
  end

  describe '#close' do
    it 'closes the connection' do
      connection = described_class.new(':memory:')
      expect(connection).to be_connected

      connection.close
      expect(connection).not_to be_connected
    end
  end
end
