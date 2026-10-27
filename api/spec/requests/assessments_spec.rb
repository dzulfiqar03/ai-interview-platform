require 'rails_helper'

RSpec.describe 'GET /api/v1/assessments', type: :request do
  before { host! 'localhost' }

  let!(:org)  { Organization.create!(name: 'Test Corp', scheme: 'test-corp',
                                     identifier: 'test-corp', host: 'localhost') }
  let!(:user) { User.create!(email: 'assessor@example.com',
                             password: 'secret123', role: 'admin') }

  it 'rejects a request without a token' do
    get '/api/v1/assessments'
    expect(response).to have_http_status(:forbidden)
  end

  it 'returns 200 for an authenticated admin in a known tenant' do
    post '/api/v1/auth/login',
         params: { email: user.email, password: 'secret123' },
         headers: { 'X-Tenant-Scheme' => 'test-corp' }, as: :json
    expect(response).to have_http_status(:ok)
    token = response.parsed_body['token']

    get '/api/v1/assessments',
        headers: { 'Authorization' => "Bearer #{token}" }
    expect(response).to have_http_status(:ok)
  end
end