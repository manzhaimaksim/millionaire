require 'rails_helper'

RSpec.feature 'USER views profile of another user', type: :feature do
  let(:current_user) { create(:user, name: 'Ли', id: 1) }
  let(:another_user) { create(:user, name: 'Джон', id: 2) }

  before(:each) do
    games = [FactoryBot.create(:game, id: 10, user_id: another_user.id, created_at: Time.parse('2020.07.29, 13:00'), current_level: 15, prize: 1000000, finished_at: Time.parse('2020.07.29, 13:30')),
             FactoryBot.create(:game, id: 20, user_id: another_user.id, created_at: Time.parse('2020.07.29, 14:00'), current_level: 0, prize: 0, finished_at: Time.parse('2020.07.29, 14:30')),
             FactoryBot.create(:game, id: 30, user_id: another_user.id, created_at: Time.parse('2020.07.29, 15:00'), current_level: 5, prize: 1000, finished_at: Time.parse('2020.07.29, 15:30'), is_failed: true),
             FactoryBot.create(:game, id: 40, user_id: another_user.id, created_at: Time.parse('2020.07.29, 16:00'), current_level: 9, prize: 16000),
             FactoryBot.create(:game, id: 50, user_id: another_user.id, created_at: Time.parse('2020.07.29, 17:00'), current_level: 8, prize: 32000, finished_at: Time.parse('2020.07.29, 20:10'), is_failed: true)]
    login_as current_user
  end

  scenario 'User views profile of another user' do
    visit "/"
    click_link 'Джон'
    expect(page).to have_current_path '/users/2'

    expect(page).to have_css('.table')

    # тестируем наличие id одной из игр на странице
    expect(page).to have_content '30'

    # тестируем наличие текущего уровня одной из игр на странице
    expect(page).to have_content '15'

    # тестируем наличие статуса игр на странице
    expect(page).to have_content 'победа'
    expect(page).to have_content 'деньги'
    expect(page).to have_content 'проигрыш'
    expect(page).to have_content 'в процессе'
    expect(page).to have_content 'время'

    expect(page).to have_content '1 000 000 ₽'
    expect(page).to have_content '29 июля, 13:00'

    expect(page).not_to have_content 'Сменить имя и пароль'
    save_and_open_page
  end
end
