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
