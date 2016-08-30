require 'sqlite3'
require 'singleton'
# require_relative 'modelbase'
require_relative 'question'
require_relative 'questionfollower'
require_relative 'questionlike'
require_relative 'reply'
require_relative 'user'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end
