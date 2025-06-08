-- Задача 3*: Комплексная оценка военной эффективности отрядов
-- [
--   {
--     "squad_id": 401,
--     "squad_name": "The Axe Lords",
--     "formation_type": "Melee",
--     "leader_name": "Urist McAxelord",
--     "total_battles": 28,
--     "victories": 22,
--     "victory_percentage": 78.57,
--     "casualty_rate": 24.32,
--     "casualty_exchange_ratio": 3.75,
--     "current_members": 8,
--     "total_members_ever": 12,
--     "retention_rate": 66.67,
--     "avg_equipment_quality": 4.28,
--     "total_training_sessions": 156,
--     "avg_training_effectiveness": 0.82,
--     "training_battle_correlation": 0.76,
--     "avg_combat_skill_improvement": 3.85,
--     "overall_effectiveness_score": 0.815,
--     "related_entities": {
--       "member_ids": [102, 104, 105, 107, 110, 115, 118, 122],
--       "equipment_ids": [5001, 5002, 5003, 5004, 5005, 5006, 5007, 5008, 5009],
--       "battle_report_ids": [1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108],
--       "training_ids": [901, 902, 903, 904, 905, 906]
--     }
--   }
-- ]


WITH members_data AS (
    SELECT sm.squad_id, 
        SUM(CASE WHEN sm.exit_date IS NOT NULL THEN 1 ELSE 0 END) AS current_members,
        COUNT(sm.dwarf_id) AS total_members,
         ROUND(
            COUNT(CASE WHEN sm.exit_date IS NULL THEN 1 END) * 100.0 / 
            NULLIF(COUNT(sm.dwarf_id), 0), 2
        ) AS retention_rate,
    FROM squad_members sm
    GROUP BY sm.squad_id
),
battles_data AS (
    SELECT sb.squad_id, 
        COUNT(report_id) AS total_battles,
        SUM(CASE WHEN sb.outcome = 'Victory' THEN 1 ELSE 0 END) AS victories,
        ROUND(
            SUM(CASE WHEN sb.outcome = 'Victory' THEN 1 ELSE 0 END) /
            COUNT(report_id) * 100, 2
            ) AS victory_percentage,
        SUM(sb.casualties) AS squad_casualties,
        SUM(sb.enemy_casualties) AS enemy_casualties,
        SUM(sb.enemy_casualties) / SUM(sb.casualties) AS casualty_exchange_ratio,
        COALESCE(JSON_ARRAYAGG(sb.report_id ORDER BY sb.report_id), JSON_ARRAY()) AS battle_report_ids
    FROM squad_battles sb 
    GROUP BY sb.squad_id       
),
equipment_data AS (
    SELECT se.squad_id, 
        ROUND(AVG(e.quality), 2) AS avg_equipment_quality,
        COALESCE(JSON_ARRAYAGG(se.equipment_id ORDER BY se.equipment_id), JSON_ARRAY()) AS equipment_ids 
    FROM squad_equipment se
    JOIN equipment e ON e.equipment_id = se.equipment_id
    GROUP BY se.squad_id
),     
training_data AS (
    SELECT st.squad_id,
        SUM(st.frequency) AS total_training_sessions,
        ROUND(AVG(st.effectiveness), 2) AS avg_training_effectiveness,
        COALESCE(JSON_ARRAYAGG(st.schedule_id ORDER BY st.schedule_id), JSON_ARRAY()) AS training_ids
    FROM squad_training st
    GROUP BY st.squad_id
),

correlation_data AS (
    SELECT 
        st.squad_id,
        ROUND(CORR(
            CASE WHEN sb.outcome = 'Victory' THEN 1.0 ELSE 0.0 END,
            st.effectiveness
        ), 2) as training_battle_correlation
    FROM squad_training st
    JOIN squad_battles sb ON st.squad_id = sb.squad_id 
    GROUP BY st.squad_id
),

skill_improvement_data AS (
    SELECT 
        sm.squad_id,
        ROUND(AVG(
            CASE 
                WHEN skill_progress.skill_improvement IS NOT NULL 
                THEN skill_progress.skill_improvement 
                ELSE 0 
            END
        ), 2) AS avg_combat_skill_improvement
    FROM squad_members sm
    LEFT JOIN (
        SELECT 
            ds.dwarf_id,
            AVG(ds.level - COALESCE(LAG(ds.level) OVER (
                PARTITION BY ds.dwarf_id, ds.skill_id 
                ORDER BY ds.date
                ), 0)
            ) AS skill_improvement
        FROM dwarf_skills ds
        GROUP BY ds.dwarf_id
    ) skill_progress ON sm.dwarf_id = skill_progress.dwarf_id
    GROUP BY sm.squad_id
)

SELECT ms.squad_id, 
        ms.formation_type,
        d.name AS leader_name,
        bd.total_battles,
        bd.victories,
        bd.victory_percentage,
        ROUND(bd.squad_casualties / NULLIF(md.total_members, 0) * 100, 2) AS casualty_rate,
        bd.casualty_exchange_ratio,
        md.current_members,
        md.total_members,
        md.retention_rate,
        ed.avg_equipment_quality,
        td.total_training_sessions,
        td.avg_training_effectiveness,
        cd.training_battle_correlation,
        si.avg_combat_skill_improvement,
        ROUND((
            (COALESCE(bd.victory_percentage, 0) / 100 * 0.4) +
            (LEAST(COALESCE(bd.casualty_exchange_ratio, 0) / 5, 1) * 0.2) +
            (COALESCE(td.avg_training_effectiveness, 0) * 0.15) +
            (COALESCE(cd.training_battle_correlation, 0) * 0.1) +
            (COALESCE(md.retention_rate, 0) / 100 * 0.1) +
            (COALESCE(ed.avg_equipment_quality, 0) / 5 * 0.05)
        ), 3) AS overall_effectiveness_score,
        JSON_OBJECT(
        'member_ids', (
            SELECT COALESCE(JSON_ARRAYAGG(sm.dwarf_id WHERE sm.exit_date IS NULL ORDER BY sm.dwarf_id), JSON_ARRAY())
            FROM squad_members sm 
            WHERE sm.squad_id = ms.squad_id AND sm.exit_date IS NULL           
        ),
        'equipment_ids', ed.equipment_ids,
        'battle_report_ids', bd.battle_report_ids,
        'training_ids', td.training_ids
    ) AS related_entities
FROM military_squads ms
JOIN DWARVES d ON d.dwarf_id = ms.leader_id
LEFT JOIN battles_data bd ON bd.squad_id = ms.squad_id
LEFT JOIN training_data td ON td.squad_id = ms.squad_id
LEFT JOIN equipment_data ed ON ed.squad_id = ms.squad_id
LEFT JOIN members_data md ON md.squad_id = ms.squad_id
LEFT JOIN correlation_data cd ON cd.squad_id = ms.squad_id
LEFT JOIN skill_improvement_data si ON  si.squad_id = ms.squad_id