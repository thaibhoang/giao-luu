ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

# Minitest 6 removed Object#stub; re-add it for compatibility
module MinitestStubCompat
  def stub(method_name, val_or_callable, *_block_args, **_kw, &block)
    original = method(method_name)
    singleton_class.define_method(method_name) do |*args, **kwargs|
      val_or_callable.respond_to?(:call) ? val_or_callable.call(*args, **kwargs) : val_or_callable
    end
    result = block.call
    result
  ensure
    singleton_class.define_method(method_name, original)
  end
end
Object.include(MinitestStubCompat)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Ensure PostGIS SRID 4326 exists and pg type map is current for this
    # connection. Called both from parallelize_setup (parallel workers) and
    # once at suite start (single-process runs).
    def self.ensure_postgis_ready!(conn = ActiveRecord::Base.connection)
      return unless conn.adapter_name.casecmp("postgresql").zero?
      return unless conn.extension_enabled?("postgis")

      conn.execute(<<~SQL)
        INSERT INTO spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text)
        VALUES (
          4326, 'EPSG', 4326,
          'GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4326"]]',
          '+proj=longlat +datum=WGS84 +no_defs'
        )
        ON CONFLICT (srid) DO NOTHING;
      SQL

      # Reload type map for every checked-out connection in the pool so that
      # geography OIDs are recognised regardless of which connection a test uses.
      ActiveRecord::Base.connection_pool.connections.each(&:reload_type_map)
    end

    # After each parallel worker creates its test DB, ensure SRID 4326 exists in
    # spatial_ref_sys. Parallel test DBs are created by loading structure.sql
    # which installs the postgis extension, but the extension data (spatial_ref_sys)
    # may not be populated when the extension was already present in the template DB.
    # We also reload the pg type map so geography columns are recognised correctly.
    parallelize_setup do |_worker|
      ensure_postgis_ready!
    end

    # For single-process runs (parallelization threshold not met), parallelize_setup
    # is never called. Reload type map lazily on first test setup so the test DB
    # is fully prepared before we introspect it.
    @@postgis_ready = false # rubocop:disable Style/ClassVars

    setup do
      unless @@postgis_ready
        self.class.ensure_postgis_ready!
        @@postgis_ready = true
      end
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
