create database placement;
use placement;

select * from Players


/*1) Identify the player with the best batting average (total runs scored divided by the number of matches played) across all matches.*/

SELECT p.PlayerName, 
       SUM(per.RunsScored) / COUNT(DISTINCT per.MatchID) AS BattingAverage
FROM Performance per
JOIN Players p ON per.PlayerID = p.PlayerID
GROUP BY p.PlayerID
ORDER BY BattingAverage DESC
LIMIT 1;

/*2)Find the team with the highest win percentage in matches played across all locations.*/


SELECT Winner, 
       COUNT(*) * 1.0 / (SELECT COUNT(*) FROM Matches) AS WinPercentage
FROM Matches
GROUP BY Winner
ORDER BY WinPercentage DESC
LIMIT 1;


/*3) Identify the player who contributed the highest percentage of their team's total runs in any single match.*/

 
SELECT p.PlayerName, 
       (per.RunsScored * 100.0 / total.TeamRuns) AS ContributionPercentage
FROM Performance per
JOIN Players p ON per.PlayerID = p.PlayerID
JOIN (
    SELECT MatchID, 
           SUM(RunsScored) AS TeamRuns
    FROM Performance
    GROUP BY MatchID
) total ON per.MatchID = total.MatchID
ORDER BY ContributionPercentage DESC
LIMIT 1;



/*4)Determine the most consistent player, defined as the one with the smallest standard deviation of runs scored across matches.*/
 
SELECT p.PlayerName, 
       STDDEV(per.RunsScored) AS StdDevRuns
FROM Performance per
JOIN Players p ON per.PlayerID = p.PlayerID
GROUP BY p.PlayerID
ORDER BY StdDevRuns ASC
LIMIT 1;


/*5)Find all matches where the combined total of runs scored, wickets taken, and catches exceeded 500.*/

 
SELECT m.MatchID, 
       m.MatchDate, 
       m.Team1, 
       m.Team2
FROM Matches m
JOIN (
    SELECT MatchID, 
           SUM(RunsScored + WicketsTaken + Catches) AS Total
    FROM Performance
    GROUP BY MatchID
) total ON m.MatchID = total.MatchID
WHERE Total > 500;


/*6)Identify the player who has won the most "Player of the Match" awards (highest runs scored or wickets taken in a match).*/

 
SELECT p.PlayerName, 
       COUNT(*) AS PlayerOfTheMatchCount
FROM Performance per
JOIN Players p ON per.PlayerID = p.PlayerID
WHERE per.RunsScored = (SELECT MAX(RunsScored) FROM Performance WHERE MatchID = per.MatchID)
   OR per.WicketsTaken = (SELECT MAX(WicketsTaken) FROM Performance WHERE MatchID = per.MatchID)
GROUP BY p.PlayerID
ORDER BY PlayerOfTheMatchCount DESC
LIMIT 1;


/*7) Determine the team that has the most diverse player roles in their squad.*/

 
SELECT TeamName, 
       COUNT(DISTINCT Role) AS RoleCount
FROM Players
GROUP BY TeamName
ORDER BY RoleCount DESC
LIMIT 1;

/*8)Identify matches where the runs scored by both teams were unequal and sort them by the smallest difference in total runs between the two teams.*/

 
SELECT m.MatchID, 
       m.Team1, 
       m.Team2, 
       ABS(SUM(CASE WHEN per.PlayerID IN (SELECT PlayerID FROM Players WHERE TeamName = m.Team1) THEN per.RunsScored ELSE 0 END) - 
           SUM(CASE WHEN per.PlayerID IN (SELECT PlayerID FROM Players WHERE TeamName = m.Team2) THEN per.RunsScored ELSE 0 END)) AS RunDifference
FROM Matches m
JOIN Performance per ON m.MatchID = per.MatchID
GROUP BY m.MatchID
HAVING RunDifference > 0
ORDER BY RunDifference ASC;


/*9)Find players who contributed (batted, bowled, or fielded) in every match that their team participated in.*/

 
SELECT p.PlayerName
FROM Players p
WHERE NOT EXISTS (
    SELECT 1
    FROM Matches m
    WHERE m.Team1 = p.TeamName OR m.Team2 = p.TeamName
    EXCEPT
    SELECT DISTINCT per.MatchID
    FROM Performance per
    WHERE per.PlayerID = p.PlayerID
);


/*10)Identify the match with the closest margin of victory, based on runs scored by both teams.*/

  
SELECT m.MatchID, 
       m.Team1, 
       m.Team2, 
       ABS(SUM(CASE WHEN per.PlayerID IN (SELECT PlayerID FROM Players WHERE TeamName = m.Team1) THEN per.RunsScored ELSE 0 END) - 
           SUM(CASE WHEN per.PlayerID IN (SELECT PlayerID FROM Players WHERE TeamName = m.Team2) THEN per.RunsScored ELSE 0 END)) AS RunDifference
FROM Matches m
JOIN Performance per ON m.MatchID = per.MatchID
GROUP BY m.MatchID
ORDER BY RunDifference ASC
LIMIT 1;


/*11)Calculate the total runs scored by each team across all matches.*/

 
SELECT p.TeamName, 
       SUM(per.RunsScored) AS TotalRuns
FROM Performance per
JOIN Players p ON per.PlayerID = p.PlayerID
GROUP BY p.TeamName;


/*12)List matches where the total wickets taken by the winning team exceeded 2.*/

 
SELECT m.MatchID, 
       m.Team1, 
       m.Team2
FROM Matches m
JOIN (
    SELECT MatchID, 
           SUM(WicketsTaken) AS TotalWickets
    FROM Performance
    WHERE PlayerID IN (SELECT PlayerID FROM Players WHERE TeamName = m.Winner)
    GROUP BY MatchID
) total ON m.MatchID = total.MatchID
WHERE TotalWickets > 2;


/*13)Retrieve the top 5 matches with the highest individual scores by any player.*/

 
SELECT m.MatchID, 
       m.MatchDate, 
       p.PlayerName, 
       per.RunsScored
FROM Performance per
JOIN Players p ON per.PlayerID = p.PlayerID
JOIN Matches m ON per.MatchID = m.MatchID
ORDER BY per.RunsScored DESC
LIMIT 5;


/*14)Identify all bowlers who have taken at least 5 wickets across all matches.*/

 
SELECT p.PlayerName
FROM Performance per
JOIN Players p ON per.PlayerID = p.PlayerID
WHERE per.WicketsTaken >= 5
GROUP BY p.PlayerID
HAVING SUM(per.WicketsTaken) >= 5;


/*15)Find the total number of catches taken by players from the team that won each match.*/

 
SELECT m.MatchID, 
       m.Winner, 
       SUM(per.Catches) AS TotalCatches
FROM Matches m
JOIN Performance per ON m.MatchID = per.MatchID
JOIN Players p ON per.PlayerID = p.PlayerID
WHERE p.TeamName = m.Winner
GROUP BY m.MatchID, m.Winner;


/*16)Identify the player with the highest combined impact score in all matches.*/

 
SELECT p.PlayerName, 
       SUM(per.RunsScored * 1.5 + per.WicketsTaken * 25 + per.Catches * 10 + per.Stumpings * 15 + per.RunOuts * 10) AS ImpactScore
FROM Performance per
JOIN Players p ON per.PlayerID = p.PlayerID
GROUP BY p.PlayerID
HAVING COUNT(per.MatchID) >= 3
ORDER BY ImpactScore DESC
LIMIT 1;


/*17)Find the match where the winning team had the narrowest margin of victory based on total runs scored by both teams.*/

 
SELECT m.MatchID, 
       m.Winner, 
       ABS(SUM(CASE WHEN p.TeamName = m.Winner THEN per.RunsScored ELSE 0 END) - 
           SUM(CASE WHEN p.TeamName != m.Winner THEN per.RunsScored ELSE 0 END)) AS Margin
FROM Matches m
JOIN Performance per ON m.MatchID = per.MatchID
JOIN Players p ON per.PlayerID = p.PlayerID
GROUP BY m.MatchID, m.Winner
ORDER BY Margin ASC
LIMIT 1;


/*18)List all players who have outperformed their teammates in terms of total runs scored in more than half the matches they played.*/

 
SELECT p.PlayerName
FROM Players p
JOIN Performance per ON p.PlayerID = per.PlayerID
GROUP BY p.PlayerID
HAVING SUM(CASE WHEN per.RunsScored > (SELECT MAX(RunsScored) FROM Performance WHERE MatchID = per.MatchID AND PlayerID != p.PlayerID) THEN 1 ELSE 0 END) > COUNT(per.MatchID) / 2;


/*19)Rank players by their average impact per match, considering only those who played at least three matches.*/

 
SELECT p.PlayerName, 
       AVG(per.RunsScored * 1.5 + per.WicketsTaken * 25 + per.Catches * 10 + per.Stumpings * 15 + per.RunOuts * 10) AS AverageImpact,
       RANK() OVER (ORDER BY AVG(per.RunsScored * 1.5 + per.WicketsTaken * 25 + per.Catches * 10 + per.Stumpings * 15 + per.RunOuts * 10) DESC) AS Rank
FROM Performance per
JOIN Players p ON per.PlayerID = p.PlayerID
GROUP BY p.PlayerID
HAVING COUNT(per.MatchID) >= 3;

/*
20)Identify the top 3 matches with the highest cumulative total runs scored by both teams.*/

 
SELECT m.MatchID, 
       m.MatchDate, 
       SUM(per.RunsScored) AS TotalRuns,
       RANK() OVER (ORDER BY SUM(per.RunsScored) DESC) AS Rank
FROM Matches m
JOIN Performance per ON m.MatchID = per.MatchID
GROUP BY m.MatchID
ORDER BY TotalRuns DESC
LIMIT 3;


/*21)For each player, calculate their running cumulative impact score across all matches they’ve played, ordered by match date.*/

 
SELECT p.PlayerName, 
       m.MatchDate, 
       SUM(per.RunsScored * 1.5 + per.WicketsTaken * 25 + per.Catches * 10 + per.Stumpings * 15 + per.RunOuts * 10) OVER (PARTITION BY p.PlayerID ORDER BY m.MatchDate) AS CumulativeImpact
FROM Performance per
JOIN Players p ON per.PlayerID = p.PlayerID
JOIN Matches m ON per.MatchID = m.MatchID
WHERE p.PlayerID IN (SELECT PlayerID FROM Performance GROUP BY PlayerID HAVING COUNT(MatchID) >= 3);