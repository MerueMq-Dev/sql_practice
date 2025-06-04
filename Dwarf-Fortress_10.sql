-- Задача 2*: Комплексный анализ эффективности производства
-- Возможный вариант выдачи:
-- [
--   {
--     "workshop_id": 301,
--     "workshop_name": "Royal Forge",
--     "workshop_type": "Smithy",
--     "num_craftsdwarves": 4,
--     "total_quantity_produced": 256,
--     "total_production_value": 187500,
--     "daily_production_rate": 3.41,
--     "value_per_material_unit": 7.82,
--     "workshop_utilization_percent": 85.33,
--     "material_conversion_ratio": 1.56,
--     "average_craftsdwarf_skill": 7.25,
--     "skill_quality_correlation": 0.83,  
--     "related_entities": {
--       "craftsdwarf_ids": [101, 103, 108, 115],
--       "product_ids": [801, 802, 803, 804, 805, 806],
--       "material_ids": [201, 204, 208, 210],
--       "project_ids": [701, 702, 703]
--     }
--   }
-- ]

workshop_craftsmen AS (
    SELECT 
        w.workshop_id AS workshop_id,
        COUNT(DISTINCT wc.dwarf_id) as num_craftsdwarves,
        AVG(ds.level) as average_craftsdwarf_skill
    FROM WORKSHOPS w
    LEFT JOIN WORKSHOP_CRAFTSDWARVES wc ON w.workshop_id = wc.workshop_id
    LEFT JOIN DWARF_SKILLS ds ON wc.dwarf_id = ds.dwarf_id
    GROUP BY w.workshop_id,
)

production_stats AS (
    SELECT 
        w.workshop_id,
        COUNT(DISTINCT DATE(wp.production_date)) as production_days,
        SUM(wp.quantity) as total_quantity_produced,
        SUM(wp.quantity * p.value) as total_production_value
    FROM WORKSHOPS w
    LEFT JOIN WORKSHOP_PRODUCTS wp ON w.workshop_id = wp.workshop_id
    LEFT JOIN PRODUCTS p ON wp.product_id = p.product_id
    GROUP BY w.workshop_id
)
material_consumption AS (
    SELECT 
        w.workshop_id,
        SUM(CASE WHEN wm.is_input = true THEN wm.quantity ELSE 0 END) as total_materials_consumed
    FROM WORKSHOPS w
    LEFT JOIN WORKSHOP_MATERIALS wm ON w.workshop_id = wm.workshop_id
    GROUP BY w.workshop_id
)
WITH paired_data AS (
    SELECT 
        w.workshop_id,
        ds.level AS skill_level,
        p.quality AS product_quality
    FROM WORKSHOPS w
    JOIN WORKSHOP_CRAFTSDWARVES wc ON w.workshop_id = wc.workshop_id
    JOIN DWARVES d ON wc.dwarf_id = d.dwarf_id
    JOIN DWARF_SKILLS ds ON d.dwarf_id = ds.dwarf_id
    JOIN WORKSHOP_PRODUCTS wp ON w.workshop_id = wp.workshop_id
    JOIN PRODUCTS p ON wp.product_id = p.product_id
),
averages AS (
    SELECT 
        workshop_id,
        AVG(skill_level) AS avg_skill,
        AVG(product_quality) AS avg_quality
    FROM paired_data
    GROUP BY workshop_id
),
correlations AS (
    SELECT 
        pd.workshop_id,
        ROUND(
            SUM((pd.skill_level - a.avg_skill) * (pd.product_quality - a.avg_quality)) /
            NULLIF(
                (SQRT(SUM(POWER(pd.skill_level - a.avg_skill, 2))) * 
                 SQRT(SUM(POWER(pd.product_quality - a.avg_quality, 2)))
                ),
                0
            ),
            3
        ) AS skill_quality_correlation
    FROM paired_data pd
    JOIN averages a ON pd.workshop_id = a.workshop_id
    GROUP BY pd.workshop_id
    HAVING COUNT(*) >= 5  
)

SELECT w.workshop_id, 
    w.name AS workshop_name,
    w.type AS workshop_type,
    COALESCE(wc.num_craftsdwarves, 0) AS num_craftsdwarves,
    COALESCE(wc.average_craftsdwarf_skill, 0) AS average_craftsdwarf_skill,
    COALESCE(ps.total_quantity_produced, 0) AS total_quantity_produced,
    COALESCE(ps.total_production_value, 0) AS total_production_value,
    CASE 
        WHEN ps.production_days > 0 THEN 
            ROUND(CAST(ps.total_quantity_produced::DECIMAL) / ps.production_days, 2)
        ELSE 0.0
    END AS daily_production_rate,
    CASE 
        WHEN mc.total_materials_consumed > 0 THEN 
            ROUND(CAST(ps.total_production_value::DECIMAL) / mc.total_materials_consumed, 2)
        ELSE 0.0
    END AS value_per_material_unit,
    CASE 
        WHEN mc.total_materials_consumed > 0 THEN 
            ROUND(CAST(ps.total_quantity_produced AS DECIMAL) / mc.total_materials_consumed, 2)
        ELSE 0.0
    END AS material_conversion_ratio,
    COALESCE(c.skill_quality_correlation, 0) AS skill_quality_correlation,
        JSON_OBJECT(
        'craftsdwarf_ids', (
            SELECT COALESCE(JSON_ARRAYAGG(wc.dwarf_id ORDER BY wc.dwarf_id), JSON_ARRAY())
            FROM workshop_craftsdwarves wc 
            WHERE w.workshop_id = wc.workshop_id
        ),
        'product_ids', (
            SELECT COALESCE(JSON_ARRAYAGG(wp.product_id ORDER BY wp.product_id), JSON_ARRAY())
            FROM workshop_products wp
            WHERE w.workshop_id = wp.workshop_id
        ),
        'material_ids', (
            SELECT COALESCE(JSON_ARRAYAGG(wm.material_id ORDER BY wm.material_id), JSON_ARRAY())
            FROM workshop_materials wm
            WHERE w.workshop_id = wm.workshop_id
        ),
        'project_ids', (
            SELECT COALESCE(JSON_ARRAYAGG(p.project_id ORDER BY p.project_id), JSON_ARRAY())
            FROM projects p
            WHERE w.workshop_id = p.workshop_id
        )
    ) AS related_entities                
FROM WORKSHOPS w
LEFT JOIN workshop_craftsmen wc ON w.workshop_id = wc.workshop_id 
LEFT JOIN production_stats ps ON w.workshop_id = ps.workshop_id 
LEFT JOIN material_consumption mc ON w.workshop_id = ps.workshop_id 
LEFT JOIN correlations c ON w.workshop_id = c.workshop_id;
