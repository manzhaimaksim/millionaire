module MySpecHelper

  # наш хелпер, для населения базы нужным количеством рандомных вопросов
  def generate_questions(number)
    number.times { create(:question) }
  end
end


RSpec.configure do |c|
  c.include MySpecHelper
end
