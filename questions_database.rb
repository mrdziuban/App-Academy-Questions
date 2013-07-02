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

  def followed_questions
    QuestionFollower.followed_questions_for_user_id(@user_id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@user_id)
  end

  # Final product: AVG of (COUNT(likes) for each of his questions)
  # FROM question_likes AS ql JOIN
  # GROUP BY
  # WHERE questions.author_id = @user_id
  def average_karma
    query = <<-SQL
      SELECT
        CASE WHEN COUNT(x.q_id) = 0
          THEN 0
        ELSE
          CAST(x.lc AS float)/COUNT(x.q_id)
        END
        AS avg
      FROM
       (SELECT COUNT(ql.user_id) AS lc, q.question_id AS q_id
        FROM questions AS q LEFT JOIN question_likes AS ql
        ON ql.question_id = q.question_id
        WHERE q.author_id = ?
        GROUP BY ql.question_id) AS x
    SQL

    likes_data = QuestionsDatabase.instance.execute(query, @user_id)

    likes_data.empty? ? nil : likes_data[0]['avg']
  end
end

class Question
  attr_reader :title, :body, :author_id, :question_id

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

    questions_data.map {|x| Question.new(x)}
  end

  def self.most_followed(n)
    QuestionFollower.most_followed_questions(n)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
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

  def followers
    QuestionFollower.followers_for_question_id(@question_id)
  end

  def likers
    QuestionLike.likers_for_question_id(@question_id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@question_id)
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

    replies_data.map {|x| Reply.new(x)}
  end

  def self.find_by_question_id(question_id)
    query = <<-SQL
      SELECT *
      FROM replies
      WHERE replies.question_id = ?
    SQL

    replies_data = QuestionsDatabase.instance.execute(query, question_id)

    return nil if replies_data.empty?

    replies_data.map {|x| Reply.new(x)}
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

  def question
    query = <<-SQL
      SELECT *
      FROM questions
      WHERE questions.question_id = ?
    SQL

    question_data = QuestionsDatabase.instance.execute(query, @question_id)

    question_data.empty? ? nil : Question.new(question_data[0])
  end

  def parent_reply
    query = <<-SQL
      SELECT *
      FROM replies
      WHERE replies.id = ?
    SQL

    replies_data = QuestionsDatabase.instance.execute(query, @parent_id)

    replies_data.empty? ? nil : Reply.new(replies_data[0])
  end

  def child_replies
    query = <<-SQL
      SELECT *
      FROM replies
      WHERE replies.parent_id = ?
    SQL

    replies_data = QuestionsDatabase.instance.execute(query, @id)

    return nil if replies_data.empty?

    replies_data.map {|x| Reply.new(x)}
  end
end

class QuestionFollower
  def initialize(options = {})
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end

  def self.followers_for_question_id(question_id)
    # Join question_followers with questions on question_id
    query = <<-SQL
      SELECT u.*
      FROM question_followers AS qf JOIN users AS u
      ON (qf.user_id = u.user_id)
      WHERE qf.question_id = ?
    SQL

    followers_data = QuestionsDatabase.instance.execute(query, question_id)

    return nil if followers_data.empty?

    followers_data.map {|x| User.new(x)}
  end

  def self.followed_questions_for_user_id(user_id)
    query = <<-SQL
      SELECT q.*
      FROM question_followers AS qf JOIN questions AS q
      ON qf.question_id = q.question_id
      WHERE qf.user_id = ?
    SQL

    questions_data = QuestionsDatabase.instance.execute(query, user_id)

    return nil if questions_data.empty?

    questions_data.map {|x| Question.new(x)}
  end

  def self.most_followed_questions(n)
    query = <<-SQL
      SELECT q.*
      FROM question_followers AS qf JOIN questions AS q
      ON qf.question_id = q.question_id
      GROUP BY qf.question_id
      ORDER BY COUNT(qf.user_id) DESC
      LIMIT ?
    SQL

    questions_data = QuestionsDatabase.instance.execute(query, n)

    return nil if questions_data.empty?

    questions_data.map {|x| Question.new(x)}
  end
end

class QuestionLike
  def initialize(options = {})
    @question_id = options['question_id']
    @user_id = options['user_id']
  end

  def self.likers_for_question_id(question_id)
    query = <<-SQL
      SELECT u.*
      FROM users AS u JOIN (
        SELECT ql.*
        FROM question_likes AS ql JOIN questions AS q
        ON ql.question_id = q.question_id
        WHERE ql.question_id = ?
      ) AS x
      ON u.user_id = x.user_id
    SQL

    users_data = QuestionsDatabase.instance.execute(query, question_id)

    return nil if users_data.empty?

    users_data.map {|x| User.new(x)}
  end

  def self.num_likes_for_question_id(question_id)
    query = <<-SQL
      SELECT COUNT(user_id) AS num
      FROM question_likes AS ql
      WHERE ql.question_id = ?
      GROUP BY ql.question_id
    SQL

    likes_data = QuestionsDatabase.instance.execute(query, question_id)

    likes_data.empty? ? nil : likes_data[0]['num']
  end

  def self.liked_questions_for_user_id(user_id)
    query = <<-SQL
      SELECT q.*
      FROM questions AS q JOIN (
        SELECT ql.*
        FROM question_likes AS ql JOIN users AS u
        ON ql.user_id = u.user_id
        WHERE ql.user_id = ?
      ) AS x
      ON q.question_id = x.question_id
    SQL

    questions_data = QuestionsDatabase.instance.execute(query, user_id)

    return nil if questions_data.empty?

    questions_data.map {|x| Question.new(x)}
  end

  def self.most_liked_questions(n)
    query = <<-SQL
      SELECT q.*
      FROM question_likes AS ql JOIN questions AS q
      ON ql.question_id = q.question_id
      GROUP BY ql.question_id
      ORDER BY COUNT(ql.user_id) DESC
      LIMIT ?
    SQL

    questions_data = QuestionsDatabase.instance.execute(query, n)

    return nil if questions_data.empty?

    questions_data.map {|x| Question.new(x)}
  end
end




















