/* ============================================================
   CASO 2 — ANÁLISIS DE SALUD DEL PIPELINE COMERCIAL
   Archivo: 05_performance_vendedores.sql

   Objetivo:
   Analizar el desempeño de los representantes comerciales
   dentro de las etapas críticas del pipeline.

   Este archivo analiza:
   1. Loss Rate por vendedor y por etapa
   2. Top 5 vendedores con mayor Loss Rate
   3. Volumen mínimo para evitar muestras pequeñas
   4. Deal Size perdido vs avanzado
   5. Diferencia de tamaño de deal
   6. Casos que requieren investigación adicional
   ============================================================ */


/* ============================================================
   1. RECONSTRUIR TRANSICIONES POR OPORTUNIDAD
   ============================================================ */

WITH Stage_Flow AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage

    FROM opportunity_stage_history
),

Sales_Stage_Flow AS (

    SELECT
        sf.opportunity_id,
        sf.current_stage,
        sf.next_stage,

        o.sales_rep_id,
        sr.sales_rep_name,
        sr.Country,

        o.Amount_usd

    FROM Stage_Flow sf

    INNER JOIN opportunities o
        ON sf.opportunity_id = o.opportunity_id

    INNER JOIN Sales_rep sr
        ON o.sales_rep_id = sr.sales_rep_id

    WHERE sf.current_stage IN (
        'discovery',
        'proposal',
        'negotiation'
    )

      AND sf.next_stage IS NOT NULL
)

SELECT TOP 100
    opportunity_id,
    sales_rep_id,
    sales_rep_name,
    Country,
    current_stage,
    next_stage,
    Amount_usd

FROM Sales_Stage_Flow

ORDER BY
    current_stage,
    sales_rep_id;


/* ============================================================
   2. LOSS RATE POR VENDEDOR Y POR ETAPA

   Esta consulta permite comparar representantes con diferentes
   volúmenes de oportunidades.

   Loss Rate =
   Lost Opportunities / Total Stage Exits
   ============================================================ */

WITH Stage_Flow AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage

    FROM opportunity_stage_history
),

Sales_Stage_Flow AS (

    SELECT
        sf.opportunity_id,
        sf.current_stage,
        sf.next_stage,

        o.sales_rep_id,
        sr.sales_rep_name,
        sr.Country

    FROM Stage_Flow sf

    INNER JOIN opportunities o
        ON sf.opportunity_id = o.opportunity_id

    INNER JOIN Sales_rep sr
        ON o.sales_rep_id = sr.sales_rep_id

    WHERE sf.current_stage IN (
        'discovery',
        'proposal',
        'negotiation'
    )

      AND sf.next_stage IS NOT NULL
)

SELECT
    sales_rep_id,
    sales_rep_name,
    Country,
    current_stage,

    COUNT(*) AS total_stage_exits,

    SUM(
        CASE
            WHEN next_stage = 'Lost' THEN 1
            ELSE 0
        END
    ) AS lost_opportunities,

    SUM(
        CASE
            WHEN next_stage <> 'Lost' THEN 1
            ELSE 0
        END
    ) AS non_lost_opportunities,

    CAST(
        SUM(
            CASE
                WHEN next_stage = 'Lost' THEN 1
                ELSE 0
            END
        ) * 100.0
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS loss_rate

FROM Sales_Stage_Flow

GROUP BY
    sales_rep_id,
    sales_rep_name,
    Country,
    current_stage

HAVING COUNT(*) >= 20

ORDER BY
    current_stage,
    loss_rate DESC;


/* ============================================================
   3. TOP 5 VENDEDORES POR LOSS RATE EN CADA ETAPA

   Se utiliza ROW_NUMBER() para rankear vendedores dentro de
   cada etapa.

   Se mantiene un mínimo de 20 salidas por etapa para evitar
   conclusiones basadas en muestras pequeñas.
   ============================================================ */

WITH Stage_Flow AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage

    FROM opportunity_stage_history
),

Sales_Stage_Flow AS (

    SELECT
        sf.opportunity_id,
        sf.current_stage,
        sf.next_stage,

        o.sales_rep_id,
        sr.sales_rep_name,
        sr.Country

    FROM Stage_Flow sf

    INNER JOIN opportunities o
        ON sf.opportunity_id = o.opportunity_id

    INNER JOIN Sales_rep sr
        ON o.sales_rep_id = sr.sales_rep_id

    WHERE sf.current_stage IN (
        'discovery',
        'proposal',
        'negotiation'
    )

      AND sf.next_stage IS NOT NULL
),

Rep_Performance AS (

    SELECT
        sales_rep_id,
        sales_rep_name,
        Country,
        current_stage,

        COUNT(*) AS total_stage_exits,

        SUM(
            CASE
                WHEN next_stage = 'Lost' THEN 1
                ELSE 0
            END
        ) AS lost_opportunities,

        CAST(
            SUM(
                CASE
                    WHEN next_stage = 'Lost' THEN 1
                    ELSE 0
                END
            ) * 100.0
            / NULLIF(COUNT(*), 0)
            AS DECIMAL(10,2)
        ) AS loss_rate

    FROM Sales_Stage_Flow

    GROUP BY
        sales_rep_id,
        sales_rep_name,
        Country,
        current_stage

    HAVING COUNT(*) >= 20
),

Ranked_Reps AS (

    SELECT
        *,

        ROW_NUMBER() OVER (
            PARTITION BY current_stage
            ORDER BY loss_rate DESC
        ) AS loss_rank

    FROM Rep_Performance
)

SELECT
    current_stage,
    loss_rank,

    sales_rep_id,
    sales_rep_name,
    Country,

    total_stage_exits,
    lost_opportunities,
    loss_rate

FROM Ranked_Reps

WHERE loss_rank <= 5

ORDER BY
    CASE current_stage
        WHEN 'discovery' THEN 1
        WHEN 'proposal' THEN 2
        WHEN 'negotiation' THEN 3
    END,
    loss_rank;


/* ============================================================
   4. CLASIFICAR DEALS COMO ADVANCED O LOST

   Para comparar Deal Size se consideran:

   Discovery:
       Advanced = Discovery → Proposal

   Proposal:
       Advanced = Proposal → Negotiation

   Negotiation:
       Advanced = Negotiation → Won

   Lost:
       cualquier transición directa hacia Lost
   ============================================================ */

WITH Stage_Flow AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage

    FROM opportunity_stage_history
),

Rep_Deals AS (

    SELECT
        sf.opportunity_id,
        sf.current_stage,
        sf.next_stage,

        o.sales_rep_id,
        sr.sales_rep_name,
        sr.Country,

        o.Amount_usd,

        CASE

            WHEN sf.current_stage = 'discovery'
                 AND sf.next_stage = 'proposal'
                THEN 'Advanced'

            WHEN sf.current_stage = 'proposal'
                 AND sf.next_stage = 'negotiation'
                THEN 'Advanced'

            WHEN sf.current_stage = 'negotiation'
                 AND sf.next_stage = 'Won'
                THEN 'Advanced'

            WHEN sf.next_stage = 'Lost'
                THEN 'Lost'

        END AS outcome

    FROM Stage_Flow sf

    INNER JOIN opportunities o
        ON sf.opportunity_id = o.opportunity_id

    INNER JOIN Sales_rep sr
        ON o.sales_rep_id = sr.sales_rep_id

    WHERE sf.current_stage IN (
        'discovery',
        'proposal',
        'negotiation'
    )
)

SELECT
    opportunity_id,
    sales_rep_id,
    sales_rep_name,
    Country,
    current_stage,
    next_stage,
    Amount_usd,
    outcome

FROM Rep_Deals

WHERE outcome IS NOT NULL

ORDER BY
    current_stage,
    sales_rep_id;


/* ============================================================
   5. COMPARAR DEAL SIZE LOST VS ADVANCED

   Permite evaluar si los vendedores con mayor Loss Rate
   manejan oportunidades perdidas de mayor valor.
   ============================================================ */

WITH Stage_Flow AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage

    FROM opportunity_stage_history
),

Rep_Deals AS (

    SELECT
        sf.opportunity_id,
        sf.current_stage,
        sf.next_stage,

        o.sales_rep_id,
        sr.sales_rep_name,
        sr.Country,

        o.Amount_usd,

        CASE

            WHEN sf.current_stage = 'discovery'
                 AND sf.next_stage = 'proposal'
                THEN 'Advanced'

            WHEN sf.current_stage = 'proposal'
                 AND sf.next_stage = 'negotiation'
                THEN 'Advanced'

            WHEN sf.current_stage = 'negotiation'
                 AND sf.next_stage = 'Won'
                THEN 'Advanced'

            WHEN sf.next_stage = 'Lost'
                THEN 'Lost'

        END AS outcome

    FROM Stage_Flow sf

    INNER JOIN opportunities o
        ON sf.opportunity_id = o.opportunity_id

    INNER JOIN Sales_rep sr
        ON o.sales_rep_id = sr.sales_rep_id

    WHERE sf.current_stage IN (
        'discovery',
        'proposal',
        'negotiation'
    )
),

Deal_Size_Comparison AS (

    SELECT
        sales_rep_id,
        sales_rep_name,
        Country,
        current_stage,

        COUNT(
            CASE
                WHEN outcome = 'Lost' THEN 1
            END
        ) AS lost_deals,

        AVG(
            CASE
                WHEN outcome = 'Lost'
                THEN Amount_usd
            END
        ) AS avg_lost_deal_usd,

        COUNT(
            CASE
                WHEN outcome = 'Advanced' THEN 1
            END
        ) AS advanced_deals,

        AVG(
            CASE
                WHEN outcome = 'Advanced'
                THEN Amount_usd
            END
        ) AS avg_advanced_deal_usd

    FROM Rep_Deals

    WHERE outcome IS NOT NULL

    GROUP BY
        sales_rep_id,
        sales_rep_name,
        Country,
        current_stage
)

SELECT
    sales_rep_id,
    sales_rep_name,
    Country,
    current_stage,

    lost_deals,

    CAST(
        avg_lost_deal_usd
        AS DECIMAL(18,2)
    ) AS avg_lost_deal_usd,

    advanced_deals,

    CAST(
        avg_advanced_deal_usd
        AS DECIMAL(18,2)
    ) AS avg_advanced_deal_usd,

    CAST(
        avg_lost_deal_usd - avg_advanced_deal_usd
        AS DECIMAL(18,2)
    ) AS deal_size_difference_usd

FROM Deal_Size_Comparison

WHERE lost_deals >= 10
  AND advanced_deals >= 10

ORDER BY
    current_stage,
    deal_size_difference_usd DESC;


/* ============================================================
   6. TABLA FINAL PARA DASHBOARD DE PERFORMANCE

   Combina:
   - volumen
   - Loss Rate
   - Lost Deals
   - Advanced Deals
   - Average Lost Deal
   - Average Advanced Deal
   - Deal Size Difference
   - ranking por etapa

   Esta consulta constituye la base principal del Dashboard 3.
   ============================================================ */

WITH Stage_Flow AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage

    FROM opportunity_stage_history
),

Sales_Flow AS (

    SELECT
        sf.opportunity_id,
        sf.current_stage,
        sf.next_stage,

        o.sales_rep_id,
        sr.sales_rep_name,
        sr.Country,

        o.Amount_usd,

        CASE

            WHEN sf.current_stage = 'discovery'
                 AND sf.next_stage = 'proposal'
                THEN 'Advanced'

            WHEN sf.current_stage = 'proposal'
                 AND sf.next_stage = 'negotiation'
                THEN 'Advanced'

            WHEN sf.current_stage = 'negotiation'
                 AND sf.next_stage = 'Won'
                THEN 'Advanced'

            WHEN sf.next_stage = 'Lost'
                THEN 'Lost'

            ELSE 'Other'

        END AS outcome

    FROM Stage_Flow sf

    INNER JOIN opportunities o
        ON sf.opportunity_id = o.opportunity_id

    INNER JOIN Sales_rep sr
        ON o.sales_rep_id = sr.sales_rep_id

    WHERE sf.current_stage IN (
        'discovery',
        'proposal',
        'negotiation'
    )

      AND sf.next_stage IS NOT NULL
),

Rep_Performance AS (

    SELECT
        sales_rep_id,
        sales_rep_name,
        Country,
        current_stage,

        COUNT(*) AS total_stage_exits,

        SUM(
            CASE
                WHEN outcome = 'Lost' THEN 1
                ELSE 0
            END
        ) AS lost_opportunities,

        SUM(
            CASE
                WHEN outcome = 'Advanced' THEN 1
                ELSE 0
            END
        ) AS advanced_opportunities,

        CAST(
            SUM(
                CASE
                    WHEN outcome = 'Lost' THEN 1
                    ELSE 0
                END
            ) * 100.0
            / NULLIF(COUNT(*), 0)
            AS DECIMAL(10,2)
        ) AS loss_rate,

        AVG(
            CASE
                WHEN outcome = 'Lost'
                THEN Amount_usd
            END
        ) AS avg_lost_deal_usd,

        AVG(
            CASE
                WHEN outcome = 'Advanced'
                THEN Amount_usd
            END
        ) AS avg_advanced_deal_usd

    FROM Sales_Flow

    GROUP BY
        sales_rep_id,
        sales_rep_name,
        Country,
        current_stage
),

Final AS (

    SELECT
        *,

        avg_lost_deal_usd
        - avg_advanced_deal_usd
        AS deal_size_difference_usd,

        ROW_NUMBER() OVER (
            PARTITION BY current_stage
            ORDER BY loss_rate DESC
        ) AS loss_rank

    FROM Rep_Performance

    WHERE total_stage_exits >= 20
)

SELECT
    sales_rep_id,
    sales_rep_name,
    Country,
    current_stage,

    total_stage_exits,
    lost_opportunities,
    advanced_opportunities,

    loss_rate,

    CAST(
        avg_lost_deal_usd
        AS DECIMAL(18,2)
    ) AS avg_lost_deal_usd,

    CAST(
        avg_advanced_deal_usd
        AS DECIMAL(18,2)
    ) AS avg_advanced_deal_usd,

    CAST(
        deal_size_difference_usd
        AS DECIMAL(18,2)
    ) AS deal_size_difference_usd,

    loss_rank

FROM Final

ORDER BY
    CASE current_stage
        WHEN 'discovery' THEN 1
        WHEN 'proposal' THEN 2
        WHEN 'negotiation' THEN 3
    END,
    loss_rank;


/* ============================================================
   7. RESULTADOS PRINCIPALES

   El análisis mostró vendedores con Loss Rates superiores
   al comportamiento general del equipo en determinadas etapas.

   Ejemplos relevantes:

   Patricia Rodríguez:
   - Discovery Loss Rate: ~31.53%
   - Negotiation Loss Rate: ~56.10%

   Camila Díaz:
   - Negotiation Loss Rate: ~52.83%

   Luis Díaz:
   - Discovery Loss Rate: ~31.30%
   - Negotiation Loss Rate: ~46.43%

   Algunos vendedores aparecen repetidamente entre los mayores
   Loss Rates en diferentes etapas.

   Esto los convierte en candidatos para una revisión adicional,
   pero no demuestra automáticamente bajo desempeño.
   ============================================================ */


/* ============================================================
   8. INTERPRETACIÓN DEL DEAL SIZE

   El análisis de Deal Size mostró tres posibles escenarios:

   1. Diferencia positiva:
      El vendedor pierde deals de mayor valor promedio.

   2. Diferencia cercana a cero:
      El tamaño del deal no parece explicar el Loss Rate.

   3. Diferencia negativa:
      El vendedor logra avanzar deals de mayor valor promedio.

   Ejemplo:

   Patricia Rodríguez en Negotiation:

   Average Lost Deal:
   ~699K USD

   Average Advanced Deal:
   ~693K USD

   Diferencia:
   ~6.7K USD

   Esto indica que el elevado Loss Rate de Patricia no parece
   explicarse principalmente por el tamaño de sus oportunidades.
   ============================================================ */


/* ============================================================
   9. INTERPRETACIÓN DE NEGOCIO

   El objetivo del ranking no es identificar "malos vendedores".

   Los resultados permiten detectar representantes que requieren
   investigación adicional.

   Las posibles líneas de investigación incluyen:

   - seguimiento
   - negociación
   - manejo de objeciones
   - pricing
   - descuentos
   - tipo de clientes
   - complejidad de las oportunidades

   La recomendación es realizar coaching dirigido y revisar
   casos concretos antes de tomar decisiones sobre desempeño.
   ============================================================ */
