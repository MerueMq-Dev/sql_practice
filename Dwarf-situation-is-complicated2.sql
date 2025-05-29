-- Задача 2: Получение данных о гноме с навыками и назначениями
-- [
--   {
--     "dwarf_id": 101,
--     "name": "Urist McMiner",
--     "age": 65,
--     "profession": "Miner",
--     "related_entities": {
--       "skill_ids": [1001, 1002, 1003],
--       "assignment_ids": [2001, 2002],
--       "squad_ids": [401],
--       "equipment_ids": [5001, 5002, 5003]
--     }
--   }
-- ]


SELECT d.dwarf_id, d.name, d.age, d.profession,
    JSON_OBJECT(
    'skill_ids', COALESCE((
        SELECT JSON_ARRAYAGG(ds.skill_id ORDER BY ds.skill_id)
        FROM dwarf_skills ds
        WHERE ds.dwarf_id = d.dwarf_id
    ), JSON_ARRAY()),
    'assignment_ids', COALESCE((
        SELECT JSON_ARRAYAGG(da.assignment_id ORDER BY da.assignment_id)
        FROM dwarf_assignments da    
        WHERE da.dwarf_id = d.dwarf_id
    ), JSON_ARRAY()),
    'squad_ids', COALESCE((
        SELECT JSON_ARRAYAGG(sm.squad_id ORDER BY sm.squad_id)
        FROM squad_members sm    
        WHERE sm.dwarf_id = d.dwarf_id
    ), JSON_ARRAY()),
    'equipment_ids', COALESCE((
        SELECT JSON_ARRAYAGG(dq.equipment_id ORDER BY dq.equipment_id)
        FROM dwarf_equipment dq    
        WHERE dq.dwarf_id = d.dwarf_id
    ), JSON_ARRAY())
    )
     AS related_entities
FROM dwarves d

-- Задача 3: Данные о мастерской с назначенными рабочими и проектами
-- [
--   {
--     "workshop_id": 301,
--     "name": "Royal Forge",
--     "type": "Smithy",
--     "quality": "Masterwork",
--     "related_entities": {
--       "craftsdwarf_ids": [101, 103],
--       "project_ids": [701, 702, 703],
--       "input_material_ids": [201, 204],
--       "output_product_ids": [801, 802]
--     }
--   }
-- ]

SELECT w.workshop_id, w.name, w.type, w.quality,
    JSON_OBJECT(
    'craftsdwarf_ids', COALESCE((
        SELECT JSON_ARRAYAGG(wc.dwarf_id ORDER BY wc.dwarf_id)
        FROM workshop_craftsdwarves wc
        WHERE wc.workshop_id = w.workshop_id
    ), JSON_ARRAY()),
    'project_ids', COALESCE((
        SELECT JSON_ARRAYAGG(p.project_id ORDER BY p.project_id)
        FROM projects p    
        WHERE p.workshop_id = w.workshop_id
    ), JSON_ARRAY()),
    'input_material_ids', COALESCE((
        SELECT JSON_ARRAYAGG(wm.material_id ORDER BY wm.material_id)
        FROM workshop_materials wm    
        WHERE wm.workshop_id = w.workshop_id AND wm.is_input
    ), JSON_ARRAY()),
    'output_product_ids', COALESCE((
        SELECT JSON_ARRAYAGG(wm.material_id ORDER BY wm.material_id)
        FROM workshop_materials wm    
        WHERE wm.workshop_id = w.workshop_id AND NOT wm.is_input
    ), JSON_ARRAY())
    )
    AS related_entities
FROM workshops w


-- Задача 4: Данные о военном отряде с составом и операциями
-- [
--   {
--     "squad_id": 401,
--     "name": "The Axe Lords",
--     "formation_type": "Melee",
--     "leader_id": 102,
--     "related_entities": {
--       "member_ids": [102, 104, 105, 107, 110],
--       "equipment_ids": [5004, 5005, 5006, 5007, 5008],
--       "operation_ids": [601, 602],
--       "training_schedule_ids": [901, 902],
--       "battle_report_ids": [1101, 1102, 1103]
--     }
--   }
-- ]

SELECT mq.squad_id, mq.name, mq.formation_type, mq.leader_id,
    JSON_OBJECT(
    'member_ids', COALESCE((
        SELECT JSON_ARRAYAGG(sq.dwarf_id ORDER BY sq.dwarf_id)
        FROM squad_members sq
        WHERE sq.squad_id = mq.squad_id
    ), JSON_ARRAY()),
    'equipment_ids', COALESCE((
        SELECT JSON_ARRAYAGG(se.equipment_id ORDER BY so.operation_id)
        FROM squad_equipment se
        WHERE se.squad_id = s.squad_id
        ), JSON_ARRAY()),
    'operation_ids', COALESCE((
        SELECT JSON_ARRAYAGG(so.operation_id ORDER BY so.operation_id)
        FROM squad_operations so      
        WHERE so.squad_id = mq.squad_id
    ), JSON_ARRAY()),
    'training_schedule_ids', COALESCE((
        SELECT JSON_ARRAYAGG(st.schedule_id ORDER BY st.schedule_id)
        FROM squad_training st      
        WHERE st.squad_id = mq.squad_id
    ), JSON_ARRAY()),
    'battle_report_ids', COALESCE((
        SELECT JSON_ARRAYAGG(sb.report_id ORDER BY sb.report_id)
        FROM squad_battles sb      
        WHERE sb.squad_id = mq.squad_id
    ), JSON_ARRAY())
    )
    AS related_entities
FROM military_squads mq
