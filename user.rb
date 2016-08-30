class User < ModelBase
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
    User.new(*user_data)
  end

  attr_accessor :fname, :lname
  attr_reader :id

  def initialize(options)
    super(options)
    @fname = options['fname']
    @lname = options['lname']
    @is_instructor = options['is_instructor']
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
    karma = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        CAST(COUNT(user_id)/COUNT(DISTINCT(question_id)) AS FLOAT) AS avg
      FROM
        questions
      LEFT OUTER JOIN
        question_likes ON question_id = questions.id
      WHERE
        author_id = ?
    SQL

    karma[0]['avg']
  end
end
