# (c) goodprogrammer.ru

require 'rails_helper'

# Тестовый сценарий для модели игрового вопроса,
# в идеале весь наш функционал (все методы) должны быть протестированы.
RSpec.describe GameQuestion, type: :model do

  # задаем локальную переменную game_question, доступную во всех тестах этого сценария
  # она будет создана на фабрике заново для каждого блока it, где она вызывается
  let(:game_question) { FactoryBot.create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  # группа тестов на игровое состояние объекта вопроса
  context 'game status' do
    # тест на правильную генерацию хэша с вариантами
    it 'correct .variants' do
      expect(game_question.variants).to eq({'a' => game_question.question.answer2,
                                            'b' => game_question.question.answer1,
                                            'c' => game_question.question.answer4,
                                            'd' => game_question.question.answer3})
    end

    it 'correct .answer_correct?' do
      # именно под буквой b в тесте мы спрятали указатель на верный ответ
      expect(game_question.answer_correct?('b')).to be_truthy
    end
  end

  # help_hash у нас имеет такой формат:
  # {
  #   fifty_fifty: ['a', 'b'], # При использовании подсказски остались варианты a и b
  #   audience_help: {'a' => 42, 'c' => 37 ...}, # Распределение голосов по вариантам a, b, c, d
  #   friend_call: 'Василий Петрович считает, что правильный ответ A'
  # }
  #

  context 'user helpers' do
    it 'correct audience_help' do
      expect(game_question.help_hash).not_to include(:audience_help)

      game_question.add_audience_help

      expect(game_question.help_hash).to include(:audience_help)

      ah = game_question.help_hash[:audience_help]
      expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
    end

    it 'correct level and text delegates' do
      expect(game_question.text).to eq(game_question.question.text)
      expect(game_question.level).to eq(game_question.question.level)
    end

    it 'correct .help_hash' do
      expect(game_question.help_hash).to eq({})

      game_question.help_hash[:some_key1] = 'some_value1'
      game_question.help_hash[:some_key2] = 'some_value2'
      game_question.help_hash[:some_key3] = 'some_value3'

      expect(game_question.save).to be_truthy
      gq = GameQuestion.find(game_question.id)

      expect(gq.help_hash).to eq({ some_key1: 'some_value1', some_key2: 'some_value2', some_key3:'some_value3' })
    end

    it 'using .fifty_fifty' do
      expect(game_question.help_hash).to eq({})
      game_question.add_fifty_fifty

      # размер хеша с вариантами равен 2
      expect(game_question.help_hash[:fifty_fifty].size).to eq(2)

      # help_hash включает в себя подсказку 50/50
      expect(game_question.help_hash).to include(:fifty_fifty)
    end

    it 'using .add_friend_call' do
      # хэш использованых подсказок не содержит подсказку звонок другу
      expect(game_question.help_hash).not_to include(:friend_call)

      # используем подсказку
      game_question.add_friend_call

      # help_hash теперь включает в себя подсказку звонок другу
      expect(game_question.help_hash).to include(:friend_call)

      fc = game_question.help_hash[:friend_call]

      # т.к. вероятность правильного ответа 80%, то можно проверить что ответ явлется строкой
      expect(fc).to be_a(String)

      # проверяем что строка содержит фразу, которая не меняется
      expect(fc).to include('считает, что это вариант')
    end

    it 'using .add_friend_call' do
      # хэш использованых подсказок не содержит подсказку звонок другу
      expect(game_question.help_hash).not_to include(:friend_call)

      # используем подсказку
      game_question.add_friend_call

      # help_hash теперь включает в себя подсказку звонок другу
      expect(game_question.help_hash).to include(:friend_call)

      fc = game_question.help_hash[:friend_call]

      # т.к. вероятность правильного ответа 80%, то можно проверить что ответ явлется строкой
      expect(fc).to be_a(String)

      # проверяем что строка содержит фразу, которая не меняется
      expect(fc).to include('считает, что это вариант')
    end
  end

  context 'test correct_answer_key' do
    it '.correct_answer_key' do
      expect(game_question.correct_answer_key).to eq('b')
    end

    it 'fifty-fifty hint contains the correct answer' do
      game_question.add_fifty_fifty
      expect(game_question.help_hash[:fifty_fifty]).to include(game_question.correct_answer_key)
    end
  end
end
