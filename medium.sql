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
    role user_role default 'user',
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

--------------------------------------- ENUM types ----------------------------------------
    -------------------------------------ENUM types ----------------------------
create type public.user_role as enum ('admin', 'user');

-------------------------------------- Create Schemas ---------------------------------------

create schema utils;
create schema dto;
create schema helper;



------------------------------------- DTO Types --------------------------------------------

create type user_register_dto as
(
    username   varchar,
    email      varchar,
    password   varchar,
    picture_id varchar,
    bio        text
);

------------------------------------- Helper functions ---------------------------------------

create procedure helper.check_null_or_blank(IN param character varying, IN message character varying DEFAULT NULL::character varying)
    language plpgsql
as
$$
begin
    if param is null or trim(param) = '' then
        raise '%', coalesce(message, concat('Invalid input', param));
    end if;
end;
$$;


create function helper.encode_password(rawpassword character varying) returns character varying
    language plpgsql
as
$$
begin
    if rawPassword is null then
        raise exception 'Invalid Password null';
    end if;
    return utils.crypt(rawPassword, utils.gen_salt('bf', 4));
end
$$;

create function helper.match_password(pswd character varying, r_pswd character varying) returns bool
    language plpgsql
as
$$
begin
    return r_pswd = utils.crypt(pswd, r_pswd);
end
$$;


CREATE function helper.cryptpassword() returns trigger
    language plpgsql
as
$$
begin
        if tg_op = 'INSERT'  OR new.password <> old.password then
            new.password = utils.crypt(new.password, utils.gen_salt('bf', 4));
        end if;

        return new;

end;
$$;


create trigger cryptpassword
    before insert or update
    on public.users
    for each row
execute function helper.cryptpassword();



------------------------------------- Utils ------------------------------------------------

create extension if not exists pgcrypto with schema utils;

------------------------------------- User function ------------------------------------------

create function auth_register(dataparam text) returns integer
    language plpgsql
as
$$
DECLARE
    newInt   INTEGER;
    datajson JSON;
    r_user   RECORD;
    dto      medium_com.dto.user_register_dto;
BEGIN
    IF dataparam IS NULL OR dataparam = '{}' THEN
        RAISE EXCEPTION 'Dataparam is not valid';
    END IF;

    datajson := dataparam::JSON;
    dto.username := datajson ->> 'username';
    dto.password := datajson ->> 'password';
    dto.email := datajson ->> 'email';
    dto.picture_id := datajson ->> 'picture_id';
    dto.bio := datajson ->> 'bio';

    CALL medium_com.helper.check_null_or_blank(dto.username, 'Username is invalid');

    SELECT INTO r_user *
    FROM users t
    WHERE t.username = lower(dto.username);

    IF FOUND THEN
        RAISE EXCEPTION 'This user already exists';
    END IF;

    CALL medium_com.helper.check_null_or_blank(dto.password, 'Password is invalid');
    CALL medium_com.helper.check_null_or_blank(dto.email, 'Email is invalid');

    IF dto.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$' THEN
        RAISE EXCEPTION 'Email should contain "@" symbol';
    END IF;

    CALL medium_com.helper.check_null_or_blank(dto.bio, 'Bio is invalid');
    CALL medium_com.helper.check_null_or_blank(dto.picture_id, 'Invalid Picture');

    INSERT INTO users (username, email, password, picture_id, bio)
    VALUES (dto.username, dto.email,
           -- helper.encode_password(dto.password),
        dto.password,
            dto.picture_id, dto.bio)
    RETURNING id INTO newInt;

    RETURN newInt;
END
$$;

create function public.auth_login(uname varchar default null::varchar, pswd varchar default null::varchar) returns text
    language plpgsql
as

$$
declare
    r_record record;
begin
    call medium_com.helper.check_null_or_blank(uname, 'Please enter valid username');
    call medium_com.helper.check_null_or_blank(pswd, 'Please enter valid password');

    select * into r_record from users t where t.username = uname;

    if not FOUND then
        raise exception using message = 'Bad credentials',
            detail = concat_ws(' ', 'Username', uname, 'already taken');
    end if;

    if helper.match_password(pswd, r_record.password) is false then
        raise exception 'Bad credentials';
    end if;


    return json_build_object(
                'id', r_record.id,
                'username' , r_record.username,
                'email', r_record.email,
                'picture_id', r_record.picture_id,
                'bio', r_record.bio
           )::text;

end
$$;





