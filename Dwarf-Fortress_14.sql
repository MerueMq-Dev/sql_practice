-- Задача 4*: Комплексный анализ торговых отношений и их влияния на крепость
-- {
--   "total_trading_partners": 5,
--   "all_time_trade_value": 15850000,
--   "all_time_trade_balance": 1250000,
--   "civilization_data": {
--     "civilization_trade_data": [
--       {
--         "civilization_type": "Human",
--         "total_caravans": 42,
--         "total_trade_value": 5240000,
--         "trade_balance": 840000,
--         "trade_relationship": "Favorable",
--         "diplomatic_correlation": 0.78,
--         "caravan_ids": [1301, 1305, 1308, 1312, 1315]
--       },
--       {
--         "civilization_type": "Elven",
--         "total_caravans": 38,
--         "total_trade_value": 4620000,
--         "trade_balance": -280000,
--         "trade_relationship": "Unfavorable",
--         "diplomatic_correlation": 0.42,
--         "caravan_ids": [1302, 1306, 1309, 1316, 1322]
--       }
--     ]
--   },
--   "critical_import_dependencies": {
--     "resource_dependency": [
--       {
--         "material_type": "Exotic Metals",
--         "dependency_score": 2850.5,
--         "total_imported": 5230,
--         "import_diversity": 4,
--         "resource_ids": [202, 208, 215]
--       },
--       {
--         "material_type": "Lumber",
--         "dependency_score": 1720.3,
--         "total_imported": 12450,
--         "import_diversity": 3,
--         "resource_ids": [203, 209, 216]
--       }
--     ]
--   },
--   "export_effectiveness": {
--     "export_effectiveness": [
--       {
--         "workshop_type": "Smithy",
--         "product_type": "Weapons",
--         "export_ratio": 78.5,
--         "avg_markup": 1.85,
--         "workshop_ids": [301, 305, 310]
--       },
--       {
--         "workshop_type": "Jewelery",
--         "product_type": "Ornaments",
--         "export_ratio": 92.3,
--         "avg_markup": 2.15,
--         "workshop_ids": [304, 309, 315]
--       }
--     ]
--   },
--   "trade_timeline": {
--     "trade_growth": [
--       {
--         "year": 205,
--         "quarter": 1,
--         "quarterly_value": 380000,
--         "quarterly_balance": 20000,
--         "trade_diversity": 3
--       },
--       {
--         "year": 205,
--         "quarter": 2,
--         "quarterly_value": 420000,
--         "quarterly_balance": 35000,
--         "trade_diversity": 4
--       }
--     ]
--   }
-- }

WITH trade_stats AS (
    SELECT 
        c.civilization_type,
        COUNT(c.caravan_id) as total_caravans,
        COALESCE(SUM(tt.value), 0) as total_trade_value,
        COALESCE(SUM(
            CASE 
                WHEN tt.balance_direction = 'Profit' THEN tt.value
                WHEN tt.balance_direction = 'Loss' THEN -tt.value
                ELSE 0
            END
        ), 0) as trade_balance,
        CASE 
            WHEN COALESCE(SUM(
                CASE 
                    WHEN tt.balance_direction = 'Profit' THEN tt.value
                    WHEN tt.balance_direction = 'Loss' THEN -tt.value
                    ELSE 0
                END
            ), 0) > 0 THEN 'Favorable'
            ELSE 'Unfavorable'
        END as trade_relationship,
        COALESCE(ROUND(
            SUM(CASE WHEN de.outcome = 'Positive' THEN 1 ELSE 0 END) * 1.0 / 
            NULLIF(COUNT(de.event_id), 0), 2
        ), 0) as diplomatic_correlation,
        COALESCE(JSON_ARRAYAGG(c.caravan_id ORDER BY c.caravan_id LIMIT 5), JSON_ARRAY()) AS caravan_ids
    FROM caravans c
    LEFT JOIN trade_transactions tt ON c.caravan_id = tt.caravan_id
    LEFT JOIN diplomatic_events de ON c.caravan_id = de.caravan_id
    GROUP BY c.civilization_type
),

workshop_stats AS (
    SELECT 
        w.type as workshop_type,
        p.type as product_type,
        COALESCE(ROUND(
            (SUM(CASE WHEN cg.type = 'Export' THEN cg.quantity ELSE 0 END) * 100.0) / 
            NULLIF(SUM(wp.quantity), 0), 1
        ), 0) as export_ratio,
        COALESCE(ROUND(
            AVG(CASE WHEN cg.type = 'Export' AND p.value > 0 
                THEN cg.value / NULLIF(p.value, 0) 
                ELSE NULL END), 2
        ), 1.0) as avg_markup,
        COALESCE(JSON_ARRAYAGG(DISTINCT w.workshop_id ORDER BY w.workshop_id), JSON_ARRAY()) as workshop_ids
    FROM workshops w
    JOIN workshop_products wp ON w.workshop_id = wp.workshop_id
    JOIN products p ON wp.product_id = p.product_id
    LEFT JOIN caravan_goods cg ON p.product_id = cg.original_product_id
    GROUP BY w.type, p.type
    HAVING export_ratio > 0
    ORDER BY export_ratio DESC
),

trade_timeline AS (
    SELECT 
    EXTRACT(YEAR FROM tt.date) AS year,
    QUARTER(tt.date) AS quarter,
    COALESCE(SUM(tt.value), 0) as quarterly_value,
    SUM(
        CASE 
            WHEN tt.balance_direction = 'Profit' THEN tt.value
            WHEN tt.balance_direction = 'Loss' THEN -tt.value
            ELSE 0
        END
    ) as quarterly_balance,
    COUNT(DISTINCT c.civilization_type) AS trade_diversity 
FROM trade_transactions tt
JOIN caravans c ON tt.caravan_id = c.caravan_id
GROUP BY EXTRACT(YEAR FROM tt.date), QUARTER(tt.date)
ORDER BY year, quarter
),

dependency_stats AS (
SELECT 
    cg.material_type,
    ROUND(
        (SUM(cg.quantity) * SUM(cg.quantity * cg.value) / 1000.0) *
        (1.0 + AVG(cg.price_fluctuation)) *
        (5.0 / NULLIF(COUNT(DISTINCT c.civilization_type), 0)),
        1
    ) AS dependency_score,
    SUM(cg.quantity) AS total_imported,
    COUNT(DISTINCT c.civilization_type) AS import_diversity,
    JSON_ARRAYAGG(DISTINCT cg.original_product_id) AS resource_ids
FROM caravan_goods cg
JOIN caravans c ON cg.caravan_id = c.caravan_id
WHERE cg.type = 'import'
  AND cg.material_type IS NOT NULL
GROUP BY cg.material_type
HAVING dependency_score > 0
ORDER BY dependency_score DESC
),

overall_stats AS (
    SELECT 
        COUNT(DISTINCT c.civilization_type) as total_trading_partners,
        COALESCE(SUM(tt.value), 0) as all_time_trade_value,
        COALESCE(SUM(
            CASE 
                WHEN tt.balance_direction = 'Profit' THEN tt.value
                WHEN tt.balance_direction = 'Loss' THEN -tt.value
                ELSE 0
            END
        ), 0) as all_time_trade_balance
    FROM caravans c
    LEFT JOIN trade_transactions tt ON c.caravan_id = tt.caravan_id
)

SELECT JSON_OBJECT(
    'total_trading_partners', os.total_trading_partners,
    'all_time_trade_value', os.all_time_trade_value,
    'all_time_trade_balance', os.all_time_trade_balance,

    'civilization_data', JSON_OBJECT(
        'civilization_trade_data', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'civilization_type', ts.civilization_type,
                    'total_caravans', ts.total_caravans,
                    'total_trade_value', ts.total_trade_value,
                    'trade_balance', ts.trade_balance,
                    'trade_relationship', ts.trade_relationship,
                    'diplomatic_correlation', ts.diplomatic_correlation,
                    'caravan_ids', ts.caravan_ids
                )
            )
            FROM trade_stats ts
        )
    ),

    'critical_import_dependencies', JSON_OBJECT(
        'resource_dependency', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'material_type', ds.material_type,
                    'dependency_score', ds.dependency_score,
                    'total_imported', ds.total_imported,
                    'import_diversity', ds.import_diversity,
                    'resource_ids', ds.resource_ids
                )
            )
            FROM dependency_stats ds
        )
    ),

    'export_effectiveness', JSON_OBJECT(
        'export_effectiveness', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'workshop_type', ws.workshop_type,
                    'product_type', ws.product_type,
                    'export_ratio', ws.export_ratio,
                    'avg_markup', ws.avg_markup,
                    'workshop_ids', ws.workshop_ids
                )
            )
            FROM workshop_stats ws
        )
    ),

    'trade_timeline', JSON_OBJECT(
        'trade_growth', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'year', tt.year,
                    'quarter', tt.quarter,
                    'quarterly_value', tt.quarterly_value,
                    'quarterly_balance', tt.quarterly_balance,
                    'trade_diversity', tt.trade_diversity
                )
            )
            FROM trade_timeline tt
        )
    )
)
FROM overall_stats os;
