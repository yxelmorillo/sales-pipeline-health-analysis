/* ============================================================
   CASO 2 — ANÁLISIS DE SALUD DEL PIPELINE COMERCIAL
   Archivo: 02_reconstruccion_del_pipeline.sql

   Objetivo:
   Reconstruir el recorrido cronológico de cada oportunidad
   dentro del pipeline comercial.

   Este archivo:
   1. Ordena las etapas por oportunidad
   2. Identifica la siguiente etapa
   3. Calcula el tiempo entre transiciones
   4. Clasifica cada movimiento como:
      - Advanced
      - Lost
      - Other
   ============================================================ */


/* ============================================================
   1. RECONSTRUIR EL ORDEN CRONOLÓGICO

   LEAD() permite identificar la siguiente etapa registrada
   dentro de cada opportunity_id.
   ============================================================ */

WITH Stage_Sequence AS (

    SELECT
        history_id,
        opportunity_id,
        Stage AS current_stage,
        stage_entered_at AS current_stage_entered_at,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage,

        LEAD(stage_entered_at) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage_entered_at

    FROM opportunity_stage_history
)

SELECT TOP 100
    opportunity_id,
    current_stage,
    current_stage_entered_at,
    next_stage,
    next_stage_entered_at

FROM Stage_Sequence

ORDER BY
    opportunity_id,
    current_stage_entered_at;


/* ============================================================
   2. CALCULAR DURACIÓN ENTRE ETAPAS

   La duración se calcula en horas y posteriormente se
   convierte a días para conservar mayor precisión.
   ============================================================ */

WITH Stage_Sequence AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,
        stage_entered_at AS current_stage_entered_at,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage,

        LEAD(stage_entered_at) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage_entered_at

    FROM opportunity_stage_history
)

SELECT
    opportunity_id,
    current_stage,
    next_stage,
    current_stage_entered_at,
    next_stage_entered_at,

    CAST(
        DATEDIFF(
            HOUR,
            current_stage_entered_at,
            next_stage_entered_at
        ) / 24.0
        AS DECIMAL(10,2)
    ) AS duration_days

FROM Stage_Sequence

WHERE next_stage IS NOT NULL
  AND next_stage_entered_at IS NOT NULL
  AND next_stage_entered_at >= current_stage_entered_at

ORDER BY
    opportunity_id,
    current_stage_entered_at;


/* ============================================================
   3. CLASIFICAR TRANSICIONES

   Pipeline oficial:

   Prospecting → Qualified → Discovery
   → Proposal → Negotiation → Won

   Cada transición se clasifica como:

   Advanced
   Lost
   Other
   ============================================================ */

WITH Stage_Sequence AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,
        stage_entered_at AS current_stage_entered_at,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage,

        LEAD(stage_entered_at) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage_entered_at

    FROM opportunity_stage_history
),

Classified_Transitions AS (

    SELECT
        opportunity_id,
        current_stage,
        next_stage,
        current_stage_entered_at,
        next_stage_entered_at,

        CAST(
            DATEDIFF(
                HOUR,
                current_stage_entered_at,
                next_stage_entered_at
            ) / 24.0
            AS DECIMAL(10,2)
        ) AS duration_days,

        CASE

            WHEN current_stage = 'Prospecting'
                 AND next_stage = 'Qualified'
                THEN 'Advanced'

            WHEN current_stage = 'Qualified'
                 AND next_stage = 'discovery'
                THEN 'Advanced'

            WHEN current_stage = 'discovery'
                 AND next_stage = 'proposal'
                THEN 'Advanced'

            WHEN current_stage = 'proposal'
                 AND next_stage = 'negotiation'
                THEN 'Advanced'

            WHEN current_stage = 'negotiation'
                 AND next_stage = 'Won'
                THEN 'Advanced'

            WHEN next_stage = 'Lost'
                THEN 'Lost'

            ELSE 'Other'

        END AS outcome

    FROM Stage_Sequence

    WHERE next_stage IS NOT NULL
      AND next_stage_entered_at IS NOT NULL
      AND next_stage_entered_at >= current_stage_entered_at
)

SELECT
    opportunity_id,
    current_stage,
    next_stage,
    current_stage_entered_at,
    next_stage_entered_at,
    duration_days,
    outcome

FROM Classified_Transitions

ORDER BY
    opportunity_id,
    current_stage_entered_at;


/* ============================================================
   4. RESUMEN DE TRANSICIONES REALES

   Permite observar cómo se están moviendo realmente las
   oportunidades dentro del CRM.
   ============================================================ */

WITH Stage_Sequence AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage

    FROM opportunity_stage_history
)

SELECT
    current_stage,
    next_stage,
    COUNT(*) AS total_transitions

FROM Stage_Sequence

WHERE next_stage IS NOT NULL

GROUP BY
    current_stage,
    next_stage

ORDER BY
    total_transitions DESC;


/* ============================================================
   5. TRANSICIONES DEL PIPELINE LINEAL OFICIAL

   Esta consulta conserva únicamente las transiciones
   consideradas normales dentro del proceso comercial.
   ============================================================ */

WITH Stage_Sequence AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,
        stage_entered_at AS current_stage_entered_at,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage,

        LEAD(stage_entered_at) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage_entered_at

    FROM opportunity_stage_history
)

SELECT
    opportunity_id,
    current_stage,
    next_stage,

    CAST(
        DATEDIFF(
            HOUR,
            current_stage_entered_at,
            next_stage_entered_at
        ) / 24.0
        AS DECIMAL(10,2)
    ) AS duration_days

FROM Stage_Sequence

WHERE
    (
        current_stage = 'Prospecting'
        AND next_stage = 'Qualified'
    )

    OR (
        current_stage = 'Qualified'
        AND next_stage = 'discovery'
    )

    OR (
        current_stage = 'discovery'
        AND next_stage = 'proposal'
    )

    OR (
        current_stage = 'proposal'
        AND next_stage = 'negotiation'
    )

    OR (
        current_stage = 'negotiation'
        AND next_stage = 'Won'
    )

ORDER BY
    opportunity_id,
    current_stage_entered_at;


/* ============================================================
   6. TRANSICIONES NO LINEALES

   Estas rutas no se eliminan.

   Se conservan porque pueden representar:
   - saltos de etapa
   - retrocesos
   - rutas secundarias
   - reclasificaciones
   - inconsistencias en el uso del CRM
   ============================================================ */

WITH Stage_Sequence AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage

    FROM opportunity_stage_history
)

SELECT
    current_stage,
    next_stage,
    COUNT(*) AS total_transitions

FROM Stage_Sequence

WHERE next_stage IS NOT NULL

  AND NOT (

        (
            current_stage = 'Prospecting'
            AND next_stage = 'Qualified'
        )

        OR (
            current_stage = 'Qualified'
            AND next_stage = 'discovery'
        )

        OR (
            current_stage = 'discovery'
            AND next_stage = 'proposal'
        )

        OR (
            current_stage = 'proposal'
            AND next_stage = 'negotiation'
        )

        OR (
            current_stage = 'negotiation'
            AND next_stage = 'Won'
        )

        OR next_stage = 'Lost'
    )

GROUP BY
    current_stage,
    next_stage

ORDER BY
    total_transitions DESC;


/* ============================================================
   CONCLUSIONES DE RECONSTRUCCIÓN

   - El historial fue ordenado cronológicamente por oportunidad.
   - LEAD() permitió identificar la siguiente etapa real.
   - Se calculó la duración entre movimientos.
   - Cada transición fue clasificada como:
        Advanced
        Lost
        Other
   - Las rutas no lineales se conservaron para no eliminar
     comportamiento potencialmente válido del CRM.
   - El pipeline oficial se utiliza como referencia para los
     principales KPIs del proyecto.
   ============================================================ */
