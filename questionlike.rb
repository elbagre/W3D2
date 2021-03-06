class QuestionLike < ModelBase

  def self.num_likes_for_question_id(question_id)
    likes = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(user_id) AS likes
      FROM
        question_likes
      WHERE
        question_id = ?
    SQL

    likes[0]['likes']
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
        COUNT(user_id) DESC
      LIMIT
        ?
    SQL

    questions.map { |question| Question.new(question) }
  end




  attr_accessor :user_id, :question_id
  attr_reader :id

  def initialize(options)
    super(options)
    @user_id = options['user_id']
    @question_id = option['question_id']
  end

end
