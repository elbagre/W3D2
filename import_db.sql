DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

DROP TABLE IF EXISTS questions;

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_follows;

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  follower_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (follower_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

DROP TABLE IF EXISTS replies;

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_id INTEGER,
  author_id INTEGER NOT NULL,
  body TEXT,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id),
  FOREIGN KEY (author_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES  questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Brian', 'Kim'),
  ('Peter', 'McKinley');

INSERT INTO
  questions (title, body, author_id)
VALUES
  ('What is life?', 'What is the meaning of life?', (SELECT id FROM users WHERE fname = 'Brian')),
  ('How do you pronounce Nam Ryul?', 'It is a korean name.', (SELECT id FROM users WHERE fname = 'Peter'));

INSERT INTO
  question_follows (follower_id, question_id)
VALUES
  (1, 1),
  (2, 2);

INSERT INTO
  replies (question_id, parent_id, author_id, body)
VALUES
  (1, NULL, 2, '42'),
  (2, NULL, 1, 'nam ryul');

INSERT INTO
  question_likes (user_id, question_id)
VALUES
  (2, 1),
  (1, 2);
