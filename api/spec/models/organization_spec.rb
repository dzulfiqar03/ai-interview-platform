require 'rails_helper'

RSpec.describe Organization, type: :model do
  def make_org(**attrs)
    described_class.create!(
      { name: 'Test Corp', scheme: 'test-corp',
        identifier: 'test-corp', host: 'test-corp.example.com' }.merge(attrs)
    )
  end

  it 'reads from the public schema' do
    expect(described_class.table_name).to eq('public.organizations')
  end

  describe '.identify' do
    it 'finds an organization by identifier' do
      org = make_org
      expect(described_class.identify('test-corp')).to eq(org)
    end

    it 'finds an organization by host' do
      org = make_org
      expect(described_class.identify('test-corp.example.com')).to eq(org)
    end

    it 'finds an organization by alias host' do
      org = make_org(alias_hosts: ['alias.example.com'])
      expect(described_class.identify('alias.example.com')).to eq(org)
    end

    it 'does not match an unknown identifier' do
      make_org
      expect(described_class.identify('nope')).to be_nil
    end
  end
end