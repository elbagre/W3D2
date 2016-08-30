require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User

  def self.find_by_name(fname, lname)
    user_data = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL

    raise 'Not in Database' if user_data.empty?
    User.new(user_data)
  end

  def self.find_by_id(id)
    user_data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL

    User.new(user_data)
  end

  attr_accessor :fname, :lname
  attr_reader :id

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
    @is_instructor = options['is_instructor']
  end

  def create
    raise 'Already in database' if @id
    QuestionsDatabase.instance.execute(<<-SQL, fname, lname, is_instructor)
      INSERT INTO
        users (fname, lname, is_instructor)
      VALUES
        (?, ?, ?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, fname, lname, is_instructor, id)
      UPDATE
        users
      SET
        fname = ?, lname = ?, is_instructor = ?
      WHERE
        id = ?
    SQL
  end

end

class Question
  attr_accessor :title, :body, :author_id
  attr_reader :id

  def self.find_by_id(id)
    question_data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL

    Question.new(question_data)
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def create
    raise 'Already in database' if @id
    QuestionsDatabase.instance.execute(<<-SQL, title, body, author_id)
      INSERT INTO
        users (title, body, author_id)
      VALUES
        (?, ?, ?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, title, body, author_id, id)
      UPDATE
        users
      SET
        title = ?, body = ?, author_id = ?
      WHERE
        id = ?
    SQL
  end
end

class QuestionFollows
  attr_accessor :follower_id, :question_id
  attr_reader :id

  def self.find_by_follow_id(follower_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, follower_id)
      SELECT
        questions.*
      FROM
        question_follows
        JOIN questions ON question_id = questions.id
      WHERE
        follower_id = ?
    SQL

    all_questions = data.map { |data| Question.new(data) }
  end

  def self.find_by_question_id(question_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        question_follows
        JOIN users ON follower_id = users.id
      WHERE
        question_id = ?
    SQL

    all_followers = data.map { |data| User.new(data) }
  end

  def initialize(options)
    @id = options['id']
    @follower_id = options['follower_id']
    @question_id = options['question_id']
  end

  def create
    raise 'Already in database' if @id
    QuestionsDatabase.instance.execute(<<-SQL, follower_id, question_id)
      INSERT INTO
        users (follower_id, question_id)
      VALUES
        (?, ?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, follower_id, question_id, id)
      UPDATE
        users
      SET
        follower_id = ?, question_id = ?
      WHERE
        id = ?
    SQL
  end
end

class Reply

  def self.find_by_question(question_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL

    data.map { |data| Reply.new(data) }
  end

  attr_accessor :question_id, :parent_id, :author_id, :body
  attr_reader :id

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
    @author_id = options['author_id']
    @body = options['body']
  end

  def create
    raise 'Already in database' if @id
    QuestionsDatabase.instance.execute(<<-SQL, question_id, parent_id, author_id, body)
      INSERT INTO
        users (question_id, parent_id, author_id, body)
      VALUES
        (?, ?, ?, ?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, question_id, parent_id, author_id, body, id)
      UPDATE
        users
      SET
        question_id = ?, parent_id = ?, author_id = ?, body = ?
      WHERE
        id = ?
    SQL
  end
end

class QuestionLikes

  def self.likes_count(question_id)
    likes = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(user_id)
      FROM
        question_likes
      WHERE
        question_id = ?
    SQL

    likes
  end

  attr_accessor :user_id, :question_id
  attr_reader :id

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = option['question_id']
  end

  def create
    raise 'Already in database' if @id
    QuestionsDatabase.instance.execute(<<-SQL, user_id, question_id)
      INSERT INTO
        users (user_id, question_id)
      VALUES
        (?, ?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, user_id, question_id, id)
      UPDATE
        users
      SET
        user_id = ?, question_id = ?
      WHERE
        id = ?
    SQL
  end
