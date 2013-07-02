require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super("user_questions.db")

    self.results_as_hash = true
    self.type_translation = true
  end
end

class User
  attr_reader :fname, :lname, :user_id

  def initialize(options = {})
    @fname = options['fname']
    @lname = options['lname']
    @user_id = options['user_id']
  end

  def self.find_by_name(fname, lname)
    query = <<-SQL
      SELECT *
      FROM users
      WHERE users.fname = ? AND users.lname = ?
    SQL

    users_data = QuestionsDatabase.instance.execute(query, fname, lname)
    users_data.empty? ? nil : User.new(users_data[0])
  end

  def self.find_by_id(id)
    query = <<-SQL
      SELECT *
      FROM users
      WHERE users.user_id = ?
    SQL

    users_data = QuestionsDatabase.instance.execute(query, id)
    users_data.empty? ? nil : User.new(users_data[0])
  end

  def authored_questions
    Question.find_by_author_id(@user_id)
  end

  def authored_replies
    Reply.find_by_user_id(@user_id)
  end
end

class Question
  attr_reader :title, :body, :author_id

  def initialize(options = {})
    @question_id = options['question_id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def self.find_by_author_id(author_id)
    query = <<-SQL
      SELECT *
      FROM questions
      WHERE questions.author_id = ?
    SQL

    questions_data = QuestionsDatabase.instance.execute(query, author_id)

    return nil if questions_data.empty?

    questions_arr = []
    questions_data.length.times do |i|
      questions_arr << Question.new(questions_data[i])
    end
    questions_arr
  end

  def author
    query = <<-SQL
      SELECT author_id
      FROM questions
      WHERE questions.author_id = ?
    SQL

    questions_data = QuestionsDatabase.instance.execute(query, @author_id)

    questions_data.empty? ? nil : User.find_by_id(questions_data[0]['author_id'])
  end

  def replies
    Reply.find_by_question_id(@question_id)
  end
end

class QuestionFollower
  def initialize(options = {})
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end
end

class Reply
  def initialize(options = {})
    @id = options['id']
    @reply = options['reply']
    @author_id = options['author_id']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
  end

  def self.find_by_user_id(user_id)
    query = <<-SQL
      SELECT *
      FROM replies
      WHERE replies.author_id = ?
    SQL

    replies_data = QuestionsDatabase.instance.execute(query, user_id)

    return nil if replies_data.empty?

    replies_arr = []
    replies_data.length.times do |i|
      replies_arr << Reply.new(replies_data[i])
    end
    replies_arr
  end

  def self.find_by_question_id(question_id)
    query = <<-SQL
      SELECT *
      FROM replies
      WHERE replies.question_id = ?
    SQL

    replies_data = QuestionsDatabase.instance.execute(query, question_id)

    return nil if replies_data.empty?

    replies_arr = []
    replies_data.length.times do |i|
      replies_arr << Reply.new(replies_data[i])
    end
    replies_arr
  end

  def author
    query = <<-SQL
      SELECT author_id
      FROM replies
      WHERE replies.author_id = ?
    SQL

    replies_data = QuestionsDatabase.instance.execute(query, @author_id)

    replies_data.empty? ? nil : User.find_by_id(replies_data[0]['author_id'])
  end
end

class QuestionLike
  def initialize(options = {})
    @question_id = options['question_id']
    @user_id = options['user_id']
  end
end




















