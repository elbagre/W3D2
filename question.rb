class Question < ModelBase
  attr_accessor :title, :body, :author_id
  attr_reader :id

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  def self.find_by_author_id(author_id)
    question_data = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL

    question_data.map { |datum| Question.new(datum) }
  end

  def self.most_followed(n)
    QuestionFollows.most_followed_questions(n)
  end

  def initialize(options)
    super(options)
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def author
    User.find_by_id(author_id)
  end

  def replies
    Reply.find_by_question(id)
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
