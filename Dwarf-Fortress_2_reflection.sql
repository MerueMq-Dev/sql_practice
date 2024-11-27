-- 1
-- Отличия от эталонного решеня только в SELECT'e. 
-- В эталонном решении все столбцы выведенны через специальный символ (*) звёздочки.
-- У меня же столбцам дан псевдоним.
SELECT squad_id as squadId, name AS squadName 
FROM Squads
WHERE leader_id IS NULL

-- 2
-- Отличия от эталонного решеня только в SELECT'e. 
-- В эталонном решении все столбцы выведенны через специальный символ (*) звёздочки.
-- У меня же столбцам дан псевдоним.
SELECT dwarf_id, name AS dwarfName, age as dwarfAge     
FROM Dwarves
WHERE age > 150 AND profession = "Warrior"

-- 3
-- Моё решение сильно отличается от эталонного решения. 
-- Во первых я не использовал оператор DISTINCT для удаления дубликатов.
-- Во вторых я использовал фильтрацию с помощью подзапроса вместо JOIN'a как в эталонном решении.     
SELECT dwarf_id as dwarfId, name as dwarfName, age as dwarfAge, profession as dwarfProfession 
FROM Dwarves
WHERE dwarf_id IN (SELECT owner_id FROM Items WHERE type = 'weapon')

-- 4
-- Моё решение сильно отличается от эталонного, тем что у меня используется ненужный JOIN.
SELECT Dwarves.dwarf_id as dwarfId, COUNT(Tasks.dwarf_id) as taskCount,  Tasks.status as taskStatus
FROM Dwarves
INNER JOIN Tasks ON Dwarves.dwarf_id = Tasks.assigned_to
GROUP BY dwarf_id, status

-- 5
-- Отличия от эталонного решеня в SELECT'e. 
-- В эталонном решении все столбцы выведенны через специальный символ (*) звёздочки. У меня же столбцам дан псевдоним.
SELECT task_id as taskId, description   
FROM Tasks
INNER JOIN Dwarves ON Tasks.assigned_to = Dwarves.dwarf_id
INNER JOIN Squads ON Dwarves.squad_id = Squads.squad_id 
WHERE Squads.name = 'Guardians'

-- 6
-- Отличия от эталонного решеня в заданных псевдонимах для столбцов и отстутвующих псевдонимов у таблиц.
SELECT Dwarves.name AS dwarfName, RelatedDwarves.name as relatedDwarfName, Relationships.relationship as relationship  
FROM Relationships
INNER JOIN Dwarves ON Relationships.dwarf_id = Dwarves.dwarf_id
INNER JOIN Dwarves AS RelatedDwarves ON Relationships.related_to = RelatedDwarves.dwarf_id