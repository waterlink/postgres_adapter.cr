require "spec"
require "../src/postgres_adapter"
require "active_record/null_adapter"

# Register our adapter as 'null' adapter, effectively overriding what was
# registered before by 'active_record':
ActiveRecord::Registry.register_adapter("null", PostgresAdapter::Adapter)

# Cleanup database before and after each example:
Spec.before_each do
  PostgresAdapter::Adapter._reset_do_this_only_in_specs_78367c96affaacd7
end
Spec.after_each do
  PostgresAdapter::Adapter._reset_do_this_only_in_specs_78367c96affaacd7
end

# Require fake adapter and kick off the integration spec
require "../modules/active_record/spec/fake_adapter"
require "../modules/active_record/spec/active_record_spec"
