--2. Create 3 Tablespaces
--a. first one with 2 Gb and 1 datafile, tablespace should be named "uber"
CREATE TABLESPACE UBER 
DATAFILE 'uber.dbf' SIZE 2000M
ONLINE;

--b. Undo tablespace with 25Mb of space and 1 datafile
CREATE UNDO TABLESPACE UNDO_UBER
DATAFILE 'undo_uber.dbf' SIZE 25M;

--c.Bigfile tablespace of 5Gb
CREATE BIGFILE TABLESPACE BIGFILE_UBER
DATAFILE 'bigfile_uber.dbf'SIZE 5000M;

--d. Set the undo tablespace to be used in the system
ALTER SYSTEM SET UNDO_TABLESPACE = UNDO_UBER SCOPE=BOTH;

--3. Create a DBA user (with the role DBA) and assign it to the tablespace called "uber", 
--this user has unlimited space on the tablespace (The user should have permission to connect)

CREATE USER UBERDBA
IDENTIFIED BY uberdba
DEFAULT TABLESPACE UBER
QUOTA UNLIMITED ON UBER;

GRANT DBA TO UBERDBA;
GRANT CREATE SESSION TO UBERDBA;
GRANT CONNECT TO UBERDBA;

--4. Create 2 profiles.
--a. Profile 1: "clerk" password life 40 days, one session per user, 10 minutes idle, 4 failed login attempts
CREATE PROFILE CLERK LIMIT
PASSWORD_LIFE_TIME 40
SESSIONS_PER_USER 1
IDLE_TIME 10
FAILED_LOGIN_ATTEMPTS 4;

--b. Profile 3: "development" password life 100 days, two session per user, 30 minutes idle, no failed login attempts
CREATE PROFILE DEVELOPMENT LIMIT
PASSWORD_LIFE_TIME 100
SESSIONS_PER_USER 2
IDLE_TIME 30
FAILED_LOGIN_ATTEMPTS UNLIMITED;

--5. Create 4 users, assign them the tablespace "uber":
CREATE USER USER1
IDENTIFIED BY user1
DEFAULT TABLESPACE UBER
PROFILE CLERK
QUOTA UNLIMITED ON UBER;

CREATE USER USER2
IDENTIFIED BY user2
DEFAULT TABLESPACE UBER
PROFILE CLERK
QUOTA UNLIMITED ON UBER;

CREATE USER USER3
IDENTIFIED BY user3
DEFAULT TABLESPACE UBER
PROFILE DEVELOPMENT
QUOTA UNLIMITED ON UBER;

CREATE USER USER4
IDENTIFIED BY user4
DEFAULT TABLESPACE UBER
PROFILE DEVELOPMENT
QUOTA UNLIMITED ON UBER;

--a. 2 of them should have the clerk profile and the remaining the development profile,
--all the users should be allow to connect to the database.

GRANT CONNECT TO USER1;
GRANT CONNECT TO USER2;
GRANT CONNECT TO USER3;
GRANT CONNECT TO USER4;

--b. Lock one user associate with clerk profile

 ALTER USER USER1 ACCOUNT LOCK;