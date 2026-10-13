# Club Elections (SQL)

A school club holds an officer election and records it in a SQLite database with two tables, `clubMembers` and `votes`. This repo has the SQL that builds the database and answers 17 questions about the members and the results, plus three extensions.

Everything is in one file: [`club_elections.sql`](club_elections.sql). Each query has a comment above it saying which question it answers and a comment below it with the result.

## Running it

In a terminal:

```
sqlite3 club.db < club_elections.sql
```

Or paste the whole file into [sqliteonline.com](https://sqliteonline.com/) and press Run. The file drops and rebuilds the tables at the top, so it can be run as many times as you want and gives the same answers.

## What is covered

| Part | Questions | SQL used |
|---|---|---|
| Members | 1 to 6 | `SELECT`, `WHERE`, `IS NULL`, `COUNT`, `GROUP BY`, `COALESCE` |
| Voting | 7 to 13 | `JOIN` (the members table joined twice), `LEFT JOIN`, subqueries, `ORDER BY`, `LIMIT` |
| Data operations | 14 to 17 | `INSERT`, `UPDATE`, `DELETE` |
| Extensions | 3 | a new `candidates` table, `MAX()` on a subquery, `UNIQUE` and `CHECK` constraints, `PRAGMA foreign_keys` |

## Answers

| # | Question | Answer |
|---|---|---|
| 1 | Who is member #5? | Eli |
| 2 | Their favorite color? | None on file (NULL) |
| 3 | Whose favorite color is blue? | Beth, Dana |
| 4 | Who has no favorite color? | Eli, Hank |
| 5 | How many members? | 8 |
| 6 | How many in 10th grade? | 3 |
| 7 | Who did member #6 vote for? | Grace |
| 8 | Who did Beth vote for? | Beth |
| 9 | Who voted for Beth? | Alice, Beth, Eli |
| 10 | Who voted for themselves? | Beth, Dana |
| 11 | Who didn't vote? | Grace, Hank |
| 12 | Election results | Beth 3, Dana 2, Grace 1 |
| 13 | Who won? | Beth |
| 14 to 17 | Add Isabel, record her vote, change it, remove it | Done with `INSERT`, `UPDATE`, `DELETE` |

## Things that were not obvious

**`= NULL` finds nothing.** `WHERE favoriteColor = NULL` returns zero rows even though two members have no color. It has to be `IS NULL`. The file runs both so the difference is visible.

**The voting questions need the same table twice.** A vote has a voter and a candidate, and both are members. The queries join `clubMembers` once as `voter` and once as `candidate`.

**Beth won with exactly half.** She has 3 of the 6 votes cast, and turnout was 6 of 8 members (75%). If the club required a majority, this would be a runoff. When Isabel's vote is switched to Dana in question 16, the race is briefly tied 3 to 3.

**`COUNT(*)` vs `COUNT(column)` after a LEFT JOIN.** In the candidates extension, Alice is running but has no votes. `COUNT(*)` reports 1 for her, because the LEFT JOIN still produces one empty row. `COUNT(votes.id)` reports 0, which is right.

**A CHECK constraint cannot stop double voting.** The extension idea says to use CHECK, but a CHECK only sees the row being inserted, so it cannot know whether that member already has a vote. `UNIQUE` on `voterId` is what actually blocks it. SQLite also cannot add a constraint to an existing table, so the script rebuilds `votes` and copies the rows over.

**SQLite ignores foreign keys by default.** Without `PRAGMA foreign_keys = ON;`, a vote from member 99 (who does not exist) is accepted. With it, SQLite refuses.

**`LIMIT 1` hides ties.** The second extension finds the winner with `MAX()` on a subquery. Unlike `ORDER BY ... LIMIT 1`, it returns every candidate tied for first.

## Tested with

SQLite 3.43. The two statements that are supposed to fail (a second vote from Alice, and a vote from a member who does not exist) are left as comments in the file so it still runs from top to bottom. Their error messages are written next to them.
