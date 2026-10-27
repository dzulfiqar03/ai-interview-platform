require 'rails_helper'

RSpec.describe Organization, type: :model do
  before do
    conn = ActiveRecord::Base.connection
    conn.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS public.organizations (
        id bigserial PRIMARY KEY, name varchar, scheme varchar, identifier varchar,
        host varchar, alias_hosts text[] DEFAULT '{}', config jsonb DEFAULT '{}',
        created_at timestamp DEFAULT now(), updated_at timestamp DEFAULT now())
    SQL
    conn.execute("DELETE FROM public.organizations")
    conn.execute("INSERT INTO public.organizations (name, scheme, identifier, host) VALUES ('Test Corp','test-corp','test-corp','localhost')")
  end

  it('reads tenants from public.organizations') { expect(Organization.count).to eq(1) }
  it('finds a tenant by identifier') { expect(Organization.identify('test-corp')&.name).to eq('Test Corp') }
  it('returns nil for an unknown tenant') { expect(Organization.identify('nope')).to be_nil }
end