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
