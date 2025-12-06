SELECT w.*
FROM Workshops w
JOIN Festivals f ON w.FestivalID = f.FestivalID
WHERE w.Difficulty = 'advanced'
  AND EXTRACT(YEAR FROM f.StartDate) = 2025;

SELECT p.PerformanceID, pr.Name AS Performer, f.Name AS Festival, s.Name AS Stage, p.StartTime
FROM Performances p
JOIN Performers pr ON p.PerformerID = pr.PerformerID
JOIN Festivals f ON p.FestivalID = f.FestivalID
JOIN Stages s ON p.StageID = s.StageID
WHERE p.VisitorsNumber > 10000;

SELECT *
FROM Festivals
WHERE EXTRACT(YEAR FROM StartDate) = 2025
   OR EXTRACT(YEAR FROM EndDate) = 2025;

SELECT *
FROM Workshops
WHERE Difficulty = 'advanced';

SELECT *
FROM Workshops
WHERE DurationHours > 4;

SELECT *
FROM Workshops
WHERE PriorKnowledge = TRUE;

SELECT *
FROM Mentors
WHERE ExperienceYears > 10;

SELECT *
FROM Mentors
WHERE EXTRACT(YEAR FROM Birthday) < 1985;

SELECT *
FROM Visitors
WHERE City = 'Split';

SELECT *
FROM Visitors
WHERE Email LIKE '%@gmail.com';

SELECT *
FROM Visitors
WHERE AGE(Birthday) < INTERVAL '25 years';

SELECT *
FROM Tickets
WHERE Price > 120;

SELECT *
FROM Tickets
WHERE Type = 'VIP';

SELECT *
FROM Tickets
WHERE Type = 'festivalska'
AND Validity = 'cijeli_festival';

SELECT *
FROM Staff
WHERE HasSafetyTraining = TRUE;