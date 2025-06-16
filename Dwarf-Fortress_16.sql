-- Задача 5*: Многофакторный анализ угроз и безопасности крепости
-- {
--   "total_recorded_attacks": 183,
--   "unique_attackers": 42,
--   "overall_defense_success_rate": 76.50,
--   "security_analysis": {
--     "threat_assessment": {
--       "current_threat_level": "Moderate",
--       "active_threats": [
--         {
--           "creature_type": "Goblin",
--           "threat_level": 3,
--           "last_sighting_date": "0205-08-12",
--           "territory_proximity": 1.2,
--           "estimated_numbers": 35,
--           "creature_ids": [124, 126, 128, 132, 136]
--         },
--         {
--           "creature_type": "Forgotten Beast",
--           "threat_level": 5,
--           "last_sighting_date": "0205-07-28",
--           "territory_proximity": 3.5,
--           "estimated_numbers": 1,
--           "creature_ids": [158]
--         }
--       ]
--     },
--     "vulnerability_analysis": [
--       {
--         "zone_id": 15,
--         "zone_name": "Eastern Gate",
--         "vulnerability_score": 0.68,
--         "historical_breaches": 8,
--         "fortification_level": 2,
--         "military_response_time": 48,
--         "defense_coverage": {
--           "structure_ids": [182, 183, 184],
--           "squad_ids": [401, 405]
--         }
--       }
--     ],
--     "defense_effectiveness": [
--       {
--         "defense_type": "Drawbridge",
--         "effectiveness_rate": 95.12,
--         "avg_enemy_casualties": 12.4,
--         "structure_ids": [185, 186, 187, 188]
--       },
--       {
--         "defense_type": "Trap Corridor",
--         "effectiveness_rate": 88.75,
--         "avg_enemy_casualties": 8.2,
--         "structure_ids": [201, 202, 203, 204]
--       }
--     ],
--     "military_readiness_assessment": [
--       {
--         "squad_id": 403,
--         "squad_name": "Crossbow Legends",
--         "readiness_score": 0.92,
--         "active_members": 7,
--         "avg_combat_skill": 8.6,
--         "combat_effectiveness": 0.85,
--         "response_coverage": [
--           {
--             "zone_id": 12,
--             "response_time": 0
--           },
--           {
--             "zone_id": 15,
--             "response_time": 36
--           }
--         ]
--       }
--     ],
--     "security_evolution": [
--       {
--         "year": 203,
--         "defense_success_rate": 68.42,
--         "total_attacks": 38,
--         "casualties": 42,
--         "year_over_year_improvement": 3.20
--       },
--       {
--         "year": 204,
--         "defense_success_rate": 72.50,
--         "total_attacks": 40,
--         "casualties": 36,
--         "year_over_year_improvement": 4.08
--       }
--     ]
--   }
-- }

WITH attack_stats AS (
    SELECT
        COUNT(ca.attack_id) AS total_recorded_attacks,
        COUNT(DISTINCT ca.creature_id) AS unique_attackers,
        ROUND(
            SUM(CASE WHEN ca.outcome = 'Defended' THEN 1 ELSE 0 END) * 100.0 / COUNT(ca.attack_id), 
            2
        ) AS overall_defense_success_rate
    FROM creature_attacks ca
),

fortress_threat_analysis AS (
    SELECT 
        c.type AS creature_type,
        c.threat_level,
        MAX(cs.date) AS last_sighting_date,
        MIN(ct.distance_to_fortress) AS territory_proximity,
        SUM(c.estimated_population) AS estimated_numbers,
        (c.threat_level * 
         COUNT(DISTINCT c.creature_id) * 
         COALESCE(SUM(c.estimated_population), 1) * 
         (1.0 / NULLIF(MIN(ct.distance_to_fortress), 0))
        ) AS threat_score
    FROM creatures c
    LEFT JOIN creature_sightings cs ON c.creature_id = cs.creature_id
    LEFT JOIN creature_territories ct ON c.creature_id = ct.creature_id
    WHERE c.active = true
    GROUP BY c.type, c.threat_level
),

creature_id_mapping AS (
    SELECT 
        c.type AS creature_type,
        JSON_ARRAYAGG(c.creature_id) AS creature_ids
    FROM creatures c
    WHERE c.active = true
    GROUP BY c.type
),

threat_level_assessment AS (
    SELECT 
        CASE 
            WHEN MAX(threat_score) >= 100 THEN 'Extreme'
            WHEN MAX(threat_score) >= 50 THEN 'High'
            WHEN MAX(threat_score) >= 20 THEN 'Moderate'
            WHEN MAX(threat_score) >= 5 THEN 'Low'
            ELSE 'Minimal'
        END AS current_threat_level
    FROM fortress_threat_analysis
),

vulnerability_analysis AS (
    SELECT 
        l.zone_id,
        l.name AS zone_name,  
        ROUND(
            LEAST(1.0, 
                GREATEST(0.0,
                    (COUNT(CASE WHEN ca.outcome = 'Defeat' THEN 1 END) * 0.08) + 
                    ((5 - COALESCE(l.fortification_level, 0)) * 0.15) + 
                    (COALESCE(AVG(ca.military_response_time_minutes), 0) * 0.01)
                )
            ), 2
        ) AS vulnerability_score,
        COUNT(CASE WHEN ca.outcome = 'Defeat' THEN 1 END) AS historical_breaches,
        l.fortification_level,
        COALESCE(ROUND(AVG(ca.military_response_time_minutes)), 0) AS military_response_time,
        JSON_OBJECT(
            'structure_ids', COALESCE(
                (SELECT JSON_ARRAYAGG(DISTINCT ds.structure_id ORDER BY ds.structure_id) 
                 FROM defense_structures ds 
                 WHERE ds.location_id = l.location_id), 
                JSON_ARRAY()
            ),
            'squad_ids', COALESCE(
                (SELECT JSON_ARRAYAGG(DISTINCT mcz.squad_id ORDER BY mcz.squad_id) 
                 FROM military_coverage_zones mcz 
                 WHERE mcz.zone_id = l.zone_id), 
                JSON_ARRAY()
            )
        ) AS defense_coverage
    FROM locations l
    LEFT JOIN creature_attacks ca ON l.location_id = ca.location_id
    GROUP BY l.zone_id, l.name, l.fortification_level
),

defense_effectiveness_stats AS (
    SELECT 
        ds.type AS defense_type,
        ROUND(
            (COUNT(CASE WHEN ca.outcome = 'Defended' THEN 1 END) * 100.0 / 
             NULLIF(COUNT(DISTINCT ca.attack_id), 0)), 
            2
        ) AS effectiveness_rate,        
        ROUND(AVG(ca.enemy_casualties), 1) AS avg_enemy_casualties
    FROM defense_structures ds
    JOIN locations l ON ds.location_id = l.location_id
    JOIN creature_attacks ca ON l.location_id = ca.location_id 
    WHERE ds.status = 'active'
    GROUP BY ds.type
    HAVING COUNT(DISTINCT ca.attack_id) >= 2
),

military_readiness AS (
    SELECT 
        s.squad_id,
        s.squad_name,
        ROUND(
            (s.training_level * 0.3 + 
             s.equipment_quality * 0.25 + 
             s.experience_level * 0.25 + 
             s.morale * 0.2), 2
        ) AS readiness_score,
        s.active_members,
        ROUND(AVG(sm.combat_skill), 1) AS avg_combat_skill,
        ROUND(
            (COUNT(CASE WHEN sm.combat_skill >= 8 THEN 1 END) * 1.0 / 
             NULLIF(s.active_members, 0)), 2
        ) AS combat_effectiveness
    FROM squads s
    LEFT JOIN squad_members sm ON s.squad_id = sm.squad_id
    WHERE s.active = true
    GROUP BY s.squad_id, s.squad_name, s.training_level, s.equipment_quality, s.experience_level, s.morale, s.active_members
),

response_coverage AS (
    SELECT 
        mcz.squad_id,
        JSON_ARRAYAGG(
            JSON_OBJECT(
                'zone_id', mcz.zone_id,
                'response_time', COALESCE(mcz.response_time_minutes, 0)
            )
        ) AS coverage_zones
    FROM military_coverage_zones mcz
    GROUP BY mcz.squad_id
),

security_evolution AS (
    SELECT 
        EXTRACT(YEAR FROM ca.date) AS year,
        ROUND(
            SUM(CASE WHEN ca.outcome = 'Defended' THEN 1 ELSE 0 END) * 100.0 / COUNT(ca.attack_id), 
            2
        ) AS defense_success_rate,
        COUNT(ca.attack_id) AS total_attacks,
        SUM(ca.casualties) AS casualties
    FROM creature_attacks ca
    GROUP BY EXTRACT(YEAR FROM ca.date)
    ORDER BY year
),

security_evolution_with_improvement AS (
    SELECT 
        year,
        defense_success_rate,
        total_attacks,
        casualties,
        ROUND(
            defense_success_rate - LAG(defense_success_rate) OVER (ORDER BY year), 
            2
        ) AS year_over_year_improvement
    FROM security_evolution
)

SELECT JSON_OBJECT(
    'total_recorded_attacks', (SELECT total_recorded_attacks FROM attack_stats),
    'unique_attackers', (SELECT unique_attackers FROM attack_stats),
    'overall_defense_success_rate', (SELECT overall_defense_success_rate FROM attack_stats),
    'security_analysis', JSON_OBJECT(
        'threat_assessment', JSON_OBJECT(
            'current_threat_level', (SELECT current_threat_level FROM threat_level_assessment),
            'active_threats', (
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'creature_type', fta.creature_type,
                        'threat_level', fta.threat_level,
                        'last_sighting_date', fta.last_sighting_date,
                        'territory_proximity', fta.territory_proximity,
                        'estimated_numbers', fta.estimated_numbers,
                        'creature_ids', (
                            SELECT cim.creature_ids
                            FROM creature_id_mapping cim
                            WHERE cim.creature_type = fta.creature_type
                        )
                    )
                )
                FROM fortress_threat_analysis fta
                WHERE fta.territory_proximity IS NOT NULL
                ORDER BY fta.threat_score DESC
            )
        ),
        'vulnerability_analysis', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'zone_id', va.zone_id,
                    'zone_name', va.zone_name,
                    'vulnerability_score', va.vulnerability_score,
                    'historical_breaches', va.historical_breaches,
                    'fortification_level', va.fortification_level,
                    'military_response_time', va.military_response_time,
                    'defense_coverage', va.defense_coverage
                )
            )
            FROM vulnerability_analysis va
            ORDER BY va.vulnerability_score DESC
        ),
        'defense_effectiveness', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'defense_type', des.defense_type,
                    'effectiveness_rate', des.effectiveness_rate,
                    'avg_enemy_casualties', des.avg_enemy_casualties,
                    'structure_ids', (
                        SELECT JSON_ARRAYAGG(DISTINCT ds.structure_id)
                        FROM defense_structures ds
                        WHERE ds.type = des.defense_type
                        AND ds.status = 'active'
                    )
                )
            )
            FROM defense_effectiveness_stats des
            ORDER BY des.effectiveness_rate DESC
        ),
        'military_readiness_assessment', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'squad_id', mr.squad_id,
                    'squad_name', mr.squad_name,
                    'readiness_score', mr.readiness_score,
                    'active_members', mr.active_members,
                    'avg_combat_skill', mr.avg_combat_skill,
                    'combat_effectiveness', mr.combat_effectiveness,
                    'response_coverage', (
                        SELECT rc.coverage_zones
                        FROM response_coverage rc
                        WHERE rc.squad_id = mr.squad_id
                    )
                )
            )
            FROM military_readiness mr
            ORDER BY mr.readiness_score DESC
        ),
        'security_evolution', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'year', sewi.year,
                    'defense_success_rate', sewi.defense_success_rate,
                    'total_attacks', sewi.total_attacks,
                    'casualties', sewi.casualties,
                    'year_over_year_improvement', sewi.year_over_year_improvement
                )
            )
            FROM security_evolution_with_improvement sewi
            WHERE sewi.year_over_year_improvement IS NOT NULL
            ORDER BY sewi.year
        )
    )
) AS fortress_security_report;