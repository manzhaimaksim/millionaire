require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  context 'user views his page' do
    before(:each) do
      current_user = FactoryBot.create(:user, name: 'Освальд')
      assign(:user, current_user)

      build_stubbed_games = build_stubbed_list(:game, 3)
      assign(:games, build_stubbed_games)

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
