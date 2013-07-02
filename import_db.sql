CREATE TABLE users (
  user_id INTEGER PRIMARY KEY,

  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL

);

CREATE TABLE questions(
  question_id INTEGER PRIMARY KEY,

  title VARCHAR(255) NOT NULL,
  body VARCHAR(255) NOT NULL,
  author_id INTEGER NOT NULL,

  FOREIGN KEY(author_id) REFERENCES users(user_id)
);

CREATE TABLE question_followers(
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(question_id),
  FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE replies(
  id INTEGER PRIMARY KEY,
  reply VARCHAR(255) NOT NULL,
  author_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  parent_id INTEGER,

  FOREIGN KEY (author_id) REFERENCES users(user_id),
  FOREIGN KEY (question_id) REFERENCES questions(question_id),
  FOREIGN KEY (parent_id) REFERENCES replies(id)
);

CREATE TABLE question_likes(
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(question_id),
  FOREIGN KEY (user_id) REFERENCES users(user_id)
);

INSERT INTO users('fname','lname')
VALUES ('John','Smith'),('Crazy','Boy');

INSERT INTO questions('title','body','author_id')
VALUES ('Some','Handsome?',1),('dumb one','why am i a boy?',2);

INSERT INTO question_followers('question_id','user_id')
VALUES (1,2),(2,1),(1,1);

INSERT INTO replies('reply','author_id','question_id','parent_id')
VALUES ('YES!',2,1,NULL),('because of genetics?',1,2,NULL),('huh?',1,1,1);

INSERT INTO question_likes('question_id','user_id')
VALUES (1,2),(2,1);
