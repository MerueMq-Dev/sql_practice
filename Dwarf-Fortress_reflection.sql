-- 1
-- Отличия от эталонного решеня только в SELECT'e. Задал псевдонимы только двум столбцам из таблицы, 
-- так же вывел слишком много не нужных столбцов.
SELECT Dwarves.name AS dwarf_name, Squads.name AS squad_name, Dwarves.*, Squads.*
FROM Dwarves
INNER JOIN Squads
    ON Dwarves.squad_id = Squads.squad_id 

-- 2
-- Отличия от эталонного решеня только в SELECT'e. Я вывел все столбцы из таблицы Dwarves,
-- но в эталонном решении вывыведено всего два столбца: name, age.
SELECT * FROM Dwarves
WHERE profession = "miner" AND squad_id IS NULL

-- 3
-- Отличия от эталонного решеня в SELECT'e, так же у меня нет дополнительной фильтрации по статусу в подзапросе. 
-- Я не стал добавлять фильтрацию в подзапрос, так как она уже происходит на уровне основного запроса
SELECT * FROM Tasks
WHERE priority = (SELECT MAX(priority) FROM Tasks)
AND Tasks.status = "pending";

-- 4
-- Отличия от эталонного решеня только в SELECT'e.
-- Вывел только имена гномов и количество их предметов, которыми они владеют. Но не вывел их профессии.
SELECT Dwarves.name, COUNT(Items.*) AS item_count
FROM Dwarves
INNER JOIN Items 
    ON Dwarves.dwarf_id = Items.owner_id
GROUP BY Dwarves.name

-- 5
-- Отличия от эталонного решеня только SELECT'e. Вывел только названия отрядов и количество гномов в отряде. 
-- Но не вывел индификатор отряда.
SELECT Squads.name, COUNT(Dwarves.*) FROM Squads
LEFT JOIN Dwarves ON Squads.squad_id = Dwarves.squad_id
GROUP BY Squads.name

-- 6
-- Отличия от эталонного решеня только в SELECT'e. Разница в псеводонимах для столбца с количеством незаконченных задач. 
SELECT Dwarves.profession, COUNT(Tasks.task_id) AS pending_tasks
FROM Dwarves
INNER JOIN Tasks ON Dwarves.dwarf_id = Tasks.assigned_to
WHERE Tasks.status IN ('pending', 'in_progress')
GROUP BY Dwarves.profession
ORDER BY pending_tasks DESC

-- 7
-- Отличия от эталонного решеня только в SELECT'e. Не задал столбцу Items.type псевдном, 
-- так же псевдним для столбца со средним возрастом гномов задан в другом стиле.  
SELECT Items.type, AVG(Dwarves.age) AS average_age
FROM Items
JOIN Dwarves ON Items.owner_id = Dwarves.dwarf_id
GROUP BY Items.type;

-- 8
-- Отличия от эталонного решеня только в SELECT'e. Я вывел только имена гномов, а в эталонном решении ещё выведены возроста и профессии  
SELECT Dwarves.name
FROM Dwarves
LEFT JOIN Items ON Dwarves.dwarf_id = Items.owner_id
WHERE Dwarves.age > (SELECT AVG(age) FROM Dwarves) AND Items.name IS NULL