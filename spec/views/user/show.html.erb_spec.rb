require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  context 'user views his page' do
    before(:each) do
      current_user = FactoryBot.create(:user, name: 'Освальд')
      assign(:user, current_user)
      assign(:games, [
               FactoryBot.build_stubbed(:game, id: 15, created_at: Time.parse('2018.01.13, 13:00'), current_level: 4, prize: 500),
               FactoryBot.build_stubbed(:game, id: 16, created_at: Time.parse('2019.02.14, 13:00'), current_level: 5, prize: 1000),
               FactoryBot.build_stubbed(:game, id: 17, created_at: Time.parse('2020.03.15, 13:00'), current_level: 15, prize: 1000000)
             ])
      sign_in current_user
      render
    end

    it 'renders player names' do
      expect(rendered).to match 'Освальд'
    end

    it 'only the current user sees the button to change the password' do
      expect(rendered).to match 'Сменить имя и пароль'
    end

    it 'fragments with the game are rendered on the page' do
      stub_template 'users/_game.html.erb' => 'User game goes here'
      render
      expect(rendered).to have_content 'User game goes here'
      expect(rendered).to match '500 ₽'
      expect(rendered).to match '1 000 ₽'
      expect(rendered).to match '1 000 000 ₽'
    end
  end

  context 'not logged in user is viewing the page' do
    before(:each) do
      assign(:user, FactoryBot.build_stubbed(:user, name: 'Освальд'))
      render
    end

    it 'renders player names' do
      expect(rendered).to match 'Освальд'
    end

    it 'another user does not see the change password button' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end
  end
end
