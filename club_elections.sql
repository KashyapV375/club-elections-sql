-- Club Elections: SQL practice project
-- Works in SQLite (tested with sqlite3 3.43 and it also pastes into sqliteonline.com).
-- Run the whole file top to bottom. It drops and rebuilds the tables first,
-- so it gives the same answers every time.

-- =====================================================================
-- SETUP (starter SQL from the project page)
-- =====================================================================
DROP TABLE IF EXISTS votes;
DROP TABLE IF EXISTS candidates;
DROP TABLE IF EXISTS clubMembers;

CREATE TABLE clubMembers (
    id            INTEGER PRIMARY KEY,
    name          TEXT    NOT NULL,
    grade         INTEGER NOT NULL,
    favoriteColor TEXT
);

INSERT INTO clubMembers (id, name, grade, favoriteColor) VALUES
    (1, 'Alice',  10, 'red'),
    (2, 'Beth',   11, 'blue'),
    (3, 'Carlos', 10, 'green'),
    (4, 'Dana',   12, 'blue'),
    (5, 'Eli',    11, NULL),
    (6, 'Fay',    10, 'red'),
    (7, 'Grace',  12, 'purple'),
    (8, 'Hank',   11, NULL);

-- voterId     = the member casting the vote
-- candidateId = the member they voted for
CREATE TABLE votes (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    voterId     INTEGER NOT NULL,
    candidateId INTEGER NOT NULL,
    FOREIGN KEY (voterId)     REFERENCES clubMembers(id),
    FOREIGN KEY (candidateId) REFERENCES clubMembers(id)
);

INSERT INTO votes (voterId, candidateId) VALUES
    (1, 2),  -- Alice  -> Beth
    (2, 2),  -- Beth   -> Beth
    (3, 4),  -- Carlos -> Dana
    (4, 4),  -- Dana   -> Dana
    (5, 2),  -- Eli    -> Beth
    (6, 7);  -- Fay    -> Grace

-- Setup check: should be 8 members and 6 votes.
SELECT COUNT(*) AS members FROM clubMembers;
-- Result: 8
SELECT COUNT(*) AS votes FROM votes;
-- Result: 6


-- =====================================================================
-- PART 1: MEMBER QUESTIONS (1-6)
-- =====================================================================

-- Q1. Who is member #5?
SELECT name FROM clubMembers WHERE id = 5;
-- Result: Eli

-- Q2. What is member #5's favorite color?
SELECT name, favoriteColor FROM clubMembers WHERE id = 5;
-- Result: Eli | NULL
-- Eli has no favorite color on file. The query still returns a row, the value is just NULL.
-- COALESCE makes that easier to read:
SELECT name, COALESCE(favoriteColor, 'none listed') AS favoriteColor FROM clubMembers WHERE id = 5;
-- Result: Eli | none listed

-- Q3. Whose favorite color is blue?
SELECT name FROM clubMembers WHERE favoriteColor = 'blue';
-- Result: Beth, Dana

-- Q4. Who doesn't have a favorite color?
SELECT name FROM clubMembers WHERE favoriteColor IS NULL;
-- Result: Eli, Hank
-- Note: WHERE favoriteColor = NULL returns nothing at all, because NULL = NULL is not true in SQL.
-- Running it both ways shows the difference:
SELECT COUNT(*) AS rows_using_equals_null FROM clubMembers WHERE favoriteColor = NULL;
-- Result: 0

-- Q5. How many members are there?
SELECT COUNT(*) AS member_count FROM clubMembers;
-- Result: 8

-- Q6. How many members are in 10th grade?
SELECT COUNT(*) AS tenth_graders FROM clubMembers WHERE grade = 10;
-- Result: 3  (Alice, Carlos, Fay)

-- Extra: the same count for every grade at once.
SELECT grade, COUNT(*) AS members FROM clubMembers GROUP BY grade ORDER BY grade;
-- Result: 10 | 3,  11 | 3,  12 | 2


-- =====================================================================
-- PART 2: VOTING QUESTIONS (7-13)
-- These need the members table twice: once for the voter, once for the candidate.
-- I call them "voter" and "candidate" so the joins are readable.
-- =====================================================================

-- Q7. Who did member #6 vote for?
SELECT candidate.name
FROM votes
JOIN clubMembers AS candidate ON candidate.id = votes.candidateId
WHERE votes.voterId = 6;
-- Result: Grace

-- Q8. Who did Beth vote for?
SELECT candidate.name
FROM votes
JOIN clubMembers AS voter     ON voter.id     = votes.voterId
JOIN clubMembers AS candidate ON candidate.id = votes.candidateId
WHERE voter.name = 'Beth';
-- Result: Beth  (she voted for herself)

-- Q9. Who voted for Beth?
SELECT voter.name
FROM votes
JOIN clubMembers AS voter     ON voter.id     = votes.voterId
JOIN clubMembers AS candidate ON candidate.id = votes.candidateId
WHERE candidate.name = 'Beth'
ORDER BY voter.name;
-- Result: Alice, Beth, Eli

-- Q10. Who voted for themselves?
SELECT voter.name
FROM votes
JOIN clubMembers AS voter ON voter.id = votes.voterId
WHERE votes.voterId = votes.candidateId;
-- Result: Beth, Dana

-- Q11. Who didn't vote?
-- LEFT JOIN keeps every member, even ones with no row in votes. Those come back with NULLs.
SELECT m.name
FROM clubMembers AS m
LEFT JOIN votes ON votes.voterId = m.id
WHERE votes.id IS NULL;
-- Result: Grace, Hank
-- Same answer a second way, as a check:
SELECT name FROM clubMembers WHERE id NOT IN (SELECT voterId FROM votes);
-- Result: Grace, Hank

-- Q12. What are the election results (candidate + vote count)?
SELECT candidate.name, COUNT(*) AS vote_count
FROM votes
JOIN clubMembers AS candidate ON candidate.id = votes.candidateId
GROUP BY candidate.id, candidate.name
ORDER BY vote_count DESC, candidate.name;
-- Result: Beth | 3,  Dana | 2,  Grace | 1

-- Q13. Who won?
SELECT candidate.name, COUNT(*) AS vote_count
FROM votes
JOIN clubMembers AS candidate ON candidate.id = votes.candidateId
GROUP BY candidate.id, candidate.name
ORDER BY vote_count DESC
LIMIT 1;
-- Result: Beth | 3
-- Worth noticing: Beth has 3 of 6 votes, which is exactly half and not more than half.
-- If the club needed a majority, this would go to a runoff. Also only 6 of 8 members voted:
SELECT COUNT(DISTINCT voterId) AS voted,
       (SELECT COUNT(*) FROM clubMembers) AS members,
       ROUND(100.0 * COUNT(DISTINCT voterId) / (SELECT COUNT(*) FROM clubMembers), 1) AS turnout_pct
FROM votes;
-- Result: 6 | 8 | 75.0


-- =====================================================================
-- PART 3: DATA OPERATIONS (14-17)
-- =====================================================================

-- Q14. Add Isabel (id 9, grade 8, favorite color purple).
INSERT INTO clubMembers (id, name, grade, favoriteColor) VALUES (9, 'Isabel', 8, 'purple');
SELECT * FROM clubMembers WHERE id = 9;
-- Result: 9 | Isabel | 8 | purple

-- Q15. Record that Isabel voted for Beth.
-- I look the ids up by name so I am not hard-coding 9 and 2.
INSERT INTO votes (voterId, candidateId)
VALUES ((SELECT id FROM clubMembers WHERE name = 'Isabel'),
        (SELECT id FROM clubMembers WHERE name = 'Beth'));
SELECT voterId, candidateId FROM votes WHERE voterId = 9;
-- Result: 9 | 2

-- Q16. Change Isabel's vote to Dana.
UPDATE votes
SET candidateId = (SELECT id FROM clubMembers WHERE name = 'Dana')
WHERE voterId = (SELECT id FROM clubMembers WHERE name = 'Isabel');
SELECT voterId, candidateId FROM votes WHERE voterId = 9;
-- Result: 9 | 4
-- With Isabel's vote the race is now tied, Beth 3 and Dana 3.

-- Q17. Remove Isabel's vote.
DELETE FROM votes
WHERE voterId = (SELECT id FROM clubMembers WHERE name = 'Isabel');
SELECT COUNT(*) AS isabel_votes FROM votes WHERE voterId = 9;
-- Result: 0
-- Every UPDATE and DELETE above has a WHERE. Without it, Q16 would have moved all 7 votes to Dana.


-- =====================================================================
-- EXTENSIONS
-- =====================================================================

-- Extension 1: a candidates table, so only people officially running show up in the results.
-- In the starter data Fay voted for Grace, but nothing says Grace was actually running.
CREATE TABLE candidates (
    memberId INTEGER PRIMARY KEY,
    FOREIGN KEY (memberId) REFERENCES clubMembers(id)
);
INSERT INTO candidates (memberId) VALUES (2), (4), (1);   -- Beth, Dana and Alice are running

-- Results, candidates only. LEFT JOIN from candidates so someone with zero votes still shows up.
SELECT m.name, COUNT(votes.id) AS vote_count
FROM candidates
JOIN clubMembers AS m ON m.id = candidates.memberId
LEFT JOIN votes ON votes.candidateId = candidates.memberId
GROUP BY m.id, m.name
ORDER BY vote_count DESC, m.name;
-- Result: Beth | 3,  Dana | 2,  Alice | 0
-- Grace's write-in vote is gone and Alice appears with 0. COUNT(votes.id) is what makes the 0 work.
-- COUNT(*) would have given Alice 1, because the LEFT JOIN still returns one (empty) row for her.

-- Votes cast for someone who was not a candidate:
SELECT voter.name AS voter, pick.name AS voted_for
FROM votes
JOIN clubMembers AS voter ON voter.id = votes.voterId
JOIN clubMembers AS pick  ON pick.id  = votes.candidateId
WHERE votes.candidateId NOT IN (SELECT memberId FROM candidates);
-- Result: Fay | Grace

-- Extension 2: the winner without ORDER BY / LIMIT, using MAX() on a subquery.
-- This version is also more honest than LIMIT 1, because if two people tie it returns both.
SELECT m.name, tally.vote_count
FROM (SELECT candidateId, COUNT(*) AS vote_count FROM votes GROUP BY candidateId) AS tally
JOIN clubMembers AS m ON m.id = tally.candidateId
WHERE tally.vote_count = (SELECT MAX(vote_count)
                          FROM (SELECT COUNT(*) AS vote_count FROM votes GROUP BY candidateId));
-- Result: Beth | 3

-- Extension 3: stop a member from voting twice.
-- The project page suggests a CHECK constraint. A CHECK can only look at the row being inserted.
-- It cannot look at other rows, so it has no way to know the member already voted.
-- The right tool is UNIQUE on voterId. There is still one CHECK here, for a rule that does fit in a
-- single row.
-- SQLite cannot add a constraint to an existing table, so the table gets rebuilt and the votes copied over.
CREATE TABLE votes_new (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    voterId     INTEGER NOT NULL UNIQUE,                 -- one vote per member
    candidateId INTEGER NOT NULL CHECK (candidateId > 0),
    FOREIGN KEY (voterId)     REFERENCES clubMembers(id),
    FOREIGN KEY (candidateId) REFERENCES clubMembers(id)
);
INSERT INTO votes_new (voterId, candidateId) SELECT voterId, candidateId FROM votes;
DROP TABLE votes;
ALTER TABLE votes_new RENAME TO votes;

SELECT COUNT(*) AS votes_after_rebuild FROM votes;
-- Result: 6

-- To see the rule work, run this line by itself. Alice (1) already voted, so SQLite refuses it:
--   INSERT INTO votes (voterId, candidateId) VALUES (1, 4);
--   Error: UNIQUE constraint failed: votes.voterId
-- It is commented out so the file still runs from top to bottom.

-- One more thing: SQLite does not enforce FOREIGN KEY unless you turn it on.
-- Without this line, a vote from member 99 (who does not exist) is accepted. With it, it is refused.
PRAGMA foreign_keys = ON;
--   INSERT INTO votes (voterId, candidateId) VALUES (99, 2);
--   Error: FOREIGN KEY constraint failed

-- Final state of the election:
SELECT m.name, COUNT(votes.id) AS vote_count
FROM candidates
JOIN clubMembers AS m ON m.id = candidates.memberId
LEFT JOIN votes ON votes.candidateId = candidates.memberId
GROUP BY m.id, m.name
ORDER BY vote_count DESC, m.name;
-- Result: Beth | 3,  Dana | 2,  Alice | 0
