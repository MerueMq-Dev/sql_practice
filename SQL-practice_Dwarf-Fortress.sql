-- 1
SELECT  Dwarves.name AS dwarf_name, Squads.name AS squad_name, Dwarves.*, Squads.*
FROM Dwarves
INNER JOIN Squads
    ON Dwarves.squad_id = Squads.squad_id 

-- 2
SELECT * FROM Dwarves
WHERE profession = "miner" AND squad_id IS NULL

-- 3
SELECT * FROM Tasks
WHERE priority = (SELECT MAX(priority) FROM Tasks)
AND Tasks.status = "pending";

-- 4
SELECT Dwarves.name FROM Dwarves, COUNT(Items.*) AS item_count
INNER JOIN Items 
    ON Dwarves.dwarf_id = Items.owner_id
GROUP BY Dwarves.name

-- 5
SELECT Squads.name, COUNT(Dwarves.*) FROM Squads
LEFT JOIN Dwarves ON Squads.squad_id = Dwarves.squad_id
GROUP BY Squads.name

-- 6
SELECT Dwarves.profession, COUNT(Tasks.task_id) AS pending_tasks
FROM Dwarves
INNER JOIN Tasks ON Dwarves.dwarf_id = Tasks.assigned_to
WHERE Tasks.status IN ('pending', 'in_progress')
GROUP BY Dwarves.profession
ORDER BY pending_tasks DESC

-- 7
SELECT Items.type, AVG(Dwarves.age) AS average_age
FROM Items
JOIN Dwarves ON Items.owner_id = Dwarves.dwarf_id
GROUP BY Items.type;

-- 8
SELECT Dwarves.name
FROM Dwarves
LEFT JOIN Items ON Dwarves.dwarf_id = Items.owner_id
WHERE Dwarves.age > (SELECT AVG(age) FROM Dwarves) AND Items.name IS NULL