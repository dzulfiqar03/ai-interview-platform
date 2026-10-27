RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS public.organizations
        (LIKE ai_interview.organizations INCLUDING ALL)
    SQL
  end

  config.before(:each) do
    ActiveRecord::Base.connection.execute('TRUNCATE public.organizations RESTART IDENTITY')
  end
end