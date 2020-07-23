# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для модели Игры
# В идеале - все методы должны быть покрыты тестами,
# в этом классе содержится ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # пользователь для создания игр
  let(:user) { FactoryBot.create(:user) }

  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # генерим 60 вопросов с 4х запасом по полю level,
      # чтобы проверить работу RANDOM при создании игры
      generate_questions(60)

      game = nil
      # создaли игру, обернули в блок, на который накладываем проверки
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(# проверка: Game.count изменился на 1 (создали в базе 1 игру)
        change(GameQuestion, :count).by(15).and(# GameQuestion.count +15
          change(Question, :count).by(0) # Game.count не должен измениться
        )
      )
      # проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      # проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end


  # тесты на основную игровую логику
  context 'game mechanics' do

    # правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # текущий уровень игры и статус
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)
      # ранее текущий вопрос стал предыдущим
      expect(game_w_questions.previous_game_question).to eq(q)
      expect(game_w_questions.current_game_question).not_to eq(q)
      # игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    # игрок забирет 0 денег, если не ответил ни на один вопрос
    it 'User takes 0 money if he has not answered any question' do
      game_w_questions.take_money!
      expect(game_w_questions.prize).to eq(0)
      expect(game_w_questions.finished?).to be_truthy
    end

    # игрок забирает деньги, если ответил хотя бы на один вопрос
    it 'User takes the money if he answered at least one question' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)
      game_w_questions.take_money!
      expect(game_w_questions.prize).to eq(100)
      expect(game_w_questions.finished?).to be_truthy
    end
  end

  context 'Statuses of game' do
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it 'fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it 'timeout' do
      game_w_questions.created_at = Time.now - 35.minutes
      game_w_questions.time_out!
      expect(game_w_questions.status).to eq(:timeout)
    end

    it 'won' do
      game_w_questions.is_failed = false
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it 'money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end

  context 'Current question and previous level' do
    it '.current_game_question' do
      # в самом начале игры первый вопрос является текущим
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions[0])

      # правильный ответ на первый вопрос, для перехода на новый уровень
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      # если правильно дан ответ на вопрос, то второй вопрос становится текущим
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions[1])
    end

    it '.previous_level' do
      # в самом начале игры предыдущий уровень равен -1
      expect(game_w_questions.previous_level).to eq(-1)

      # правильный ответ на первый вопрос, для перехода на новый уровень
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      # предыдущий уровень становится равен 0
      expect(game_w_questions.previous_level).to eq(0)
    end
  end

  context 'answer_current_question!' do
    it 'Correct answer' do
      expect(game_w_questions.current_level).to eq(0)

      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      expect(game_w_questions.previous_game_question).to eq(q)
      expect(game_w_questions.current_level).to eq(1)
      expect(game_w_questions.status).to eq(:in_progress)
    end

    it 'Incorrect answer' do
      expect(game_w_questions.current_level).to eq(0)
      q = game_w_questions.current_game_question

      # выбираем случайный вариант из неправильных ваирантов
      hash_of_answers = q.variants.except(q.correct_answer_key)
      answer = hash_of_answers[hash_of_answers.keys.sample]

      game_w_questions.answer_current_question!(answer)
      expect(game_w_questions.current_level).to eq(0)
      expect(game_w_questions.status).to eq(:fail)
    end

    it 'Answer for last question' do
      expect(game_w_questions.current_level).to eq(0)
      q = game_w_questions.current_game_question
      game_w_questions.current_level = Question::QUESTION_LEVELS.max
      expect(game_w_questions.current_level).to eq(14)

      game_w_questions.answer_current_question!(q.correct_answer_key)
      expect(game_w_questions.current_level).to eq(15)
      expect(game_w_questions.status).to eq(:won)
      expect(game_w_questions.prize).to eq(1000000)
    end

    it 'Answered after time expires' do
      expect(game_w_questions.current_level).to eq(0)
      q = game_w_questions.current_game_question
      game_w_questions.created_at = Time.now - 35.minutes
      game_w_questions.time_out!
      expect(game_w_questions.answer_current_question!(q.correct_answer_key)).to be_falsey
      expect(game_w_questions.status).to eq(:timeout)
    end
  end
end
