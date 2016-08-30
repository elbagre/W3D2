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

  def save
    if @id
      update
    else
      create
    end
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

  def authored_questions
    Question.find_by_author_id(id)
  end

  def authored_replies
    Reply.find_by_author_id(id)
  end

  def followed_questions
    QuestionFollows.followed_questions_for_user_id(id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(id)
  end

  def average_karma
    QuestionDatabase.instance.execute(<<-SQL, id)
      SELECT
        CAST(COUNT(user_id)/COUNT(DISTINCT(question_id)) AS FLOAT)
      FROM
        questions
      LEFT OUTER JOIN
        question_likes ON question_id = questions.id
      WHERE
        author_id = ?
    SQL
  end
end

class Question
  attr_accessor :title, :body, :author_id
  attr_reader :id

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  def self.find_by_author_id(author_id)
    question_data = QuestionDatabase.instance.exectute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL

    question_data.map { |datum| Question.new(datum) }
  end

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

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def save
    if @id
      update
    else
      create
    end
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

  def author
    User.find_by_id(author_id)
  end

  def replies
    Reply.find_by_question_id(id)
  end

  def followers
    QuestionFollows.followers_for_question_id(id)
  end

  def liker
    QuestionLike.likers_for_question_id(id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(id)
  end
end

class QuestionFollows
  attr_accessor :follower_id, :question_id
  attr_reader :id

  def self.most_followed_questions(n)
    question_data = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.*
      FROM
        question_follows
        JOIN questions ON question_id = questions.id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(follower_id) DESC
      LIMIT
        ?
    SQL

    question_data.map { |datum| Question.new(datum) }
  end

  def self.followed_questions_for_user_id(follower_id)
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

  def self.followers_for_question_id(question_id)
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

  def save
    if @id
      update
    else
      create
    end
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

  def self.find_by_author_id(author_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        replies
      WHERE
        author_id = ?
    SQL

    data.map { |datum| Reply.new(datum) }
  end


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

  def save
    if @id
      update
    else
      create
    end
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

  def author
    User.find_by_id(author_id)
  end

  def question
    Question.find_by_id(question_id)
  end

  def parent_reply
    Reply.find_by_id(parent_id)
  end

  def child_replies
    children = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_id = ?
    SQL

    children.map { |child| Reply.new(child) }
  end
end

class QuestionLike

  def self.num_likes_for_question_id(question_id)
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

  def self.likers_for_question_id(question_id)
    likers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        question_likes
      JOIN
        users ON users.id = user_id
      WHERE
        question_id = ?
    SQL

    likers.map { |liker| User.new(liker) }
  end

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        question_likes
      JOIN
        questions ON questions.id = question_id
      WHERE
        user_id = ?
    SQL

    questions.map { |question| Question.new(question) }
  end

  def self.most_liked_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.*
      FROM
        question_likes
      JOIN
        questions ON question_id = questions.id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(user_id)
      LIMIT
        n
    SQL

    questions.map { |question| Question.new(question) }
  end




  attr_accessor :user_id, :question_id
  attr_reader :id

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = option['question_id']
  end

  def save
    if @id
      update
    else
      create
    end
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
