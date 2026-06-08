require 'spec_helper'

RSpec.describe 'HTTP endpoints', type: :request do
  def post_json(path, payload)
    post path, payload.to_json, { 'CONTENT_TYPE' => 'application/json' }
  end

  describe 'POST /operation' do
    it 'returns calculation for Postman example body' do
      post_json '/operation', {
        user_id: 1,
        positions: [
          { id: 1, price: 100, quantity: 3 },
          { id: 2, price: 50,  quantity: 2 },
          { id: 3, price: 40,  quantity: 1 },
          { id: 4, price: 150, quantity: 2 }
        ]
      }
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body, symbolize_names: true)
      expect(body[:status]).to eq('ok')
      expect(body[:summ]).to eq(734)
      expect(body[:positions].size).to eq(4)
      expect(body[:operation_id]).to be_an(Integer)
    end

    it 'returns 404 when user is unknown' do
      post_json '/operation', { user_id: 999_999, positions: [{ id: 1, price: 1, quantity: 1 }] }
      expect(last_response.status).to eq(404)
    end

    it 'returns 400 on invalid JSON' do
      post '/operation', 'not-json', { 'CONTENT_TYPE' => 'application/json' }
      expect(last_response.status).to eq(400)
    end
  end

  describe 'POST /submit' do
    let(:user) { Teyca::Models::User[1] }

    def create_operation(positions = [{ id: 1, price: 100, quantity: 1 }])
      post_json '/operation', { user_id: user.id, positions: positions }
      JSON.parse(last_response.body, symbolize_names: true)
    end

    it 'confirms an operation and returns the new totals' do
      op = create_operation
      post_json '/submit', {
        user: { id: user.id, template_id: user.template_id, name: user.name, bonus: user.bonus.to_s },
        operation_id: op[:operation_id],
        write_off: 30
      }
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body, symbolize_names: true)
      expect(body[:status]).to eq('ok')
      expect(body[:operation][:write_off]).to eq(30)
      expect(body[:operation][:to_pay]).to eq(70)
    end

    it 'returns 422 when write_off exceeds allowed' do
      op = create_operation
      post_json '/submit', {
        user: { id: user.id, template_id: user.template_id, name: user.name, bonus: user.bonus.to_s },
        operation_id: op[:operation_id],
        write_off: 10_000
      }
      expect(last_response.status).to eq(422)
    end
  end
end
