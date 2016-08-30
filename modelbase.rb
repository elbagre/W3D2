class ModelBase

  def self.all

  end

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.to_s.tableize}
      WHERE
        id = ?
    SQL

    data.map { |datum| self.new(datum) }
  end

  def initialize(options)
    @id = options['id']
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

    variables = self.instance_variables.drop(1)
    values = variables.map { |symbol| self.instance_variable_get(symbol) }

    question_string = Array.new(variables.count) { '?' }.join(', ')

    string_var = variables.map(&:to_s).join(', ').gsub(/@/, "")
    table_name = self.class.to_s.tableize

    QuestionsDatabase.instance.execute(<<-SQL, *values)
      INSERT INTO
        #{table_name} (#{string_var})
      VALUES
        (#{question_string})
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id

    variables = self.instance_variables.rotate
    values = variables.map { |symbol| self.instance_variable_get(symbol) }

    set_string = variables[0..-1].map do |var|
      var.to_s + " = ?"
    end.join(", ").gsub(/@/, "")

    table_name = self.class.to_s.tableize

    QuestionsDatabase.instance.execute(<<-SQL, *values)
      UPDATE
        #{table_name}
      SET
        #{set_string}
      WHERE
        id = ?
    SQL
  end

end
