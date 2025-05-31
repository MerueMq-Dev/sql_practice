-- Задача 1*: Анализ эффективности экспедиций
-- [
--   {
--     "expedition_id": 2301,
--     "destination": "Ancient Ruins",
--     "status": "Completed",
--     "survival_rate": 71.43,
--     "artifacts_value": 28500,
--     "discovered_sites": 3,
--     "encounter_success_rate": 66.67,
--     "skill_improvement": 14,
--     "expedition_duration": 44,
--     "overall_success_score": 0.78,
--     "related_entities": {
--       "member_ids": [102, 104, 107, 110, 112, 115, 118],
--       "artifact_ids": [2501, 2502, 2503],
--       "site_ids": [2401, 2402, 2403]
--     }
--   }
-- ]


SELECT e.expedition_id,
 e.destination,
 e.status,
 CASE
  WHEN members_data.all_expedition_members_count IS NULL OR members_data.all_expedition_members_count = 0 THEN 0
  ELSE ROUND(
    COALESCE(members_data.survived_expedition_members_count, 0) * 100.0 /
    members_data.all_expedition_members_count, 2)
 END AS survival_rate,
 COALESCE(artifacts_data.artifacts_value_sum, 0) AS artifacts_value,
 COALESCE(sites_data.discovered_sites_count, 0) AS discovered_sites,
 CASE
 WHEN creatures_data.all_outcome_count IS NULL OR creatures_data.all_expedition_members_count = 0 THEN 0
 ELSE ROUND(
    COALESCE(creatures_data.positive_outcome_count, 0) * 100.0 / creatures_data.all_outcome_count, 2)
 END AS encounter_success_rate,
 COALESCE(skills_data.total_skill_improvement, 0) AS skill_improvement,
 TIMESTAMPDIFF(DAY, e.departure_date, e.return_date) as expedition_duration,
 ROUND((
    (COALESCE(members_data.survived_expedition_members_count * 1.0 / NULLIF(members_data.all_expedition_members_count, 0), 0)) * 0.35 +
    (COALESCE(creatures_data.positive_outcome_count * 1.0 / NULLIF(creatures_data.all_outcome_count, 0), 0)) * 0.30 +
    (LEAST(LOG(COALESCE(artifacts_data.artifacts_value_sum, 1) + 1) / LOG(100001), 1.0)) * 0.20 +
    (LEAST(COALESCE(sites_data.discovered_sites_count, 0) / 8.0, 1.0)) * 0.10 +
    (LEAST(COALESCE(skills_data.total_skill_improvement, 0) / 40.0, 1.0)) * 0.05
  ), 2) AS overall_success_score,
    JSON_OBJECT(
    'member_ids', COALESCE(members_data.member_ids, JSON_ARRAY()),
    'artifact_ids', COALESCE(artifacts_data.artifact_ids, JSON_ARRAY()),
    'site_ids', COALESCE(sites_data.site_ids, JSON_ARRAY())
    ) AS related_entities
FROM expeditions e

LEFT JOIN (
    SELECT es.expedition_id, 
    JSON_ARRAYAGG(es.site_id ORDER BY es.site_id) AS site_ids,
    COUNT(*) AS discovered_sites_count 
    FROM expedition_sites es
    GROUP BY es.expedition_id
) sites_data ON sites_data.expedition_id = e.expedition_id

LEFT JOIN (
    SELECT ea.expedition_id,
    JSON_ARRAYAGG(ea.artifact_id ORDER BY ea.artifact_id) as artifact_ids,
    SUM(ea.value) as artifacts_value_sum
    FROM expedition_artifacts ea 
    GROUP BY ea.expedition_id
) artifacts_data ON e.expedition_id = artifacts_data.expedition_id

LEFT JOIN (
    SELECT em.expedition_id, 
    JSON_ARRAYAGG(em.dwarf_id ORDER BY em.dwarf_id) AS member_ids,
    COUNT(*) AS all_expedition_members_count,
    SUM(CASE WHEN em.survived THEN 1 ELSE 0) AS survived_expedition_members_count
    FROM expedition_members em 
    GROUP BY em.expedition_id
) members_data ON e.expedition_id = members_data.expedition_id

LEFT JOIN (
    SELECT ec.expedition_id,
    COUNT(*) as all_outcome_count,
    SUM(CASE WHEN ec.outcome THEN 1 ELSE 0) AS positive_outcome_count
    FROM expedition_creatures EXPEDITION_CREATURES ec 
    GROUP BY ec.expedition_id
) creatures_data ON e.expedition_id = creatures_data.expedition_id

LEFT JOIN (
    SELECT 
        improvements.expedition_id AS expedition_id,
        SUM(improvements.skill_improvement) AS total_skill_improvement
    FROM (
        SELECT 
            e_skills.expedition_id,
            em_skills.dwarf_id,
            ds.skill_id,
            MAX(CASE WHEN ds.date >= e_skills.return_date THEN ds.level END) -
            MAX(CASE WHEN ds.date <= e_skills.departure_date THEN ds.level END) AS skill_improvement
            
        FROM expeditions e_skills
        JOIN expedition_members em_skills ON e_skills.expedition_id = em_skills.expedition_id
        JOIN dwarf_skills ds ON em_skills.dwarf_id = ds.dwarf_id
        
        WHERE e_skills.status = 'Completed'
        GROUP BY e_skills.expedition_id, em_skills.dwarf_id, ds.skill_id
        HAVING skill_improvement IS NOT NULL
    ) improvements   
    GROUP BY expedition_id
) skills_data ON e.expedition_id = skills_data.expedition_id  

WHERE e.status = 'Completed'
ORDER BY e.expedition_id