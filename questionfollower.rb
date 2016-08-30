
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
