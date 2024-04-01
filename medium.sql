CREATE SEQUENCE users_sequence
    START 1
    INCREMENT 1;

CREATE SEQUENCE articles_sequence
    START 1
    INCREMENT 1;

CREATE SEQUENCE tags_sequence
    START 1
    INCREMENT 1;

CREATE SEQUENCE comments_sequence
    START 1
    INCREMENT 1;

CREATE SEQUENCE comments_sequence
    START 1
    INCREMENT 1;

CREATE SEQUENCE followers_sequence
    START 1
    INCREMENT 1;

CREATE SEQUENCE bookmarks_sequence
    START 1
    INCREMENT 1;

CREATE SEQUENCE likes_sequence
    START 1
    INCREMENT 1;

CREATE TABLE users (
    id INT DEFAULT NEXTVAL('users_sequence') PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    password VARCHAR(100) NOT NULL,
    picture_id VARCHAR(255),
    bio TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);


CREATE TABLE articles (
    id INT DEFAULT NEXTVAL('articles_sequence') PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    authorid INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    views INT DEFAULT 0,
    likes INT DEFAULT 0,
    comments INT DEFAULT 0,
    FOREIGN KEY (authorid) REFERENCES users(id)
);

CREATE TABLE tags (
    tagid INT DEFAULT NEXTVAL('tags_sequence') PRIMARY KEY,
    tagname VARCHAR(50) NOT NULL
);


CREATE TABLE comments (
    commentid INT DEFAULT NEXTVAL('comments_sequence') PRIMARY KEY,
    articleid INT,
    userid INT,
    comment TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (articleid) REFERENCES articles(id),
    FOREIGN KEY (userid) REFERENCES users(id)
);

CREATE TABLE followers (
    followerid INT DEFAULT NEXTVAL('followers_sequence'),
    followeeid INT,
    PRIMARY KEY (followerid, followeeid),
    FOREIGN KEY (followerid) REFERENCES users(id)
);


CREATE TABLE bookmarks (
    bookmarkid INT DEFAULT NEXTVAL('bookmarks_sequence') PRIMARY KEY,
    userid INT,
    articleid INT,
    bookmarkdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (userid) REFERENCES users(id),
    FOREIGN KEY (articleid) REFERENCES articles(id)
);


CREATE TABLE likes (
    likeid INT DEFAULT NEXTVAL('likes_sequence') PRIMARY KEY,
    userid INT,
    articleid INT,
    likedate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (userid) REFERENCES users(id),
    FOREIGN KEY (articleid) REFERENCES articles(id)
);




