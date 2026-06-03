DROP TABLE IF EXISTS _benchmark_resultados CASCADE;
DROP FUNCTION IF EXISTS benchmark_query(TEXT, TEXT, TEXT, INT) CASCADE;

CREATE TABLE _benchmark_resultados (
    id              SERIAL PRIMARY KEY,
    cenario         TEXT NOT NULL,           
    id_consulta     TEXT NOT NULL,           
    tipo_execucao   TEXT NOT NULL,           
    iteracao        INT  NOT NULL,           
    custo_startup   NUMERIC,                 
    custo_total     NUMERIC,                 
    tempo_plan_ms   NUMERIC,                 
    tempo_exec_ms   NUMERIC,                 
    tempo_total_ms  NUMERIC,                 
    plano_resumo    TEXT,                     
    coletado_em     TIMESTAMP DEFAULT clock_timestamp()
);

CREATE OR REPLACE FUNCTION benchmark_query(
    p_cenario       TEXT,       
    p_id_consulta   TEXT,       
    p_sql           TEXT,       
    p_iteracoes     INT DEFAULT 5   
)
RETURNS VOID AS $$
DECLARE
    i               INT;
    v_plano_json    JSONB;
    v_custo_startup NUMERIC;
    v_custo_total   NUMERIC;
    v_tempo_plan    NUMERIC;
    v_tempo_exec    NUMERIC;
    v_tipo_no       TEXT;
    v_tipo_exec     TEXT;
BEGIN
    FOR i IN 1 .. p_iteracoes LOOP

        DEALLOCATE ALL;
        RESET ALL;

        EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ' || p_sql
        INTO v_plano_json;

        v_tempo_plan    := (v_plano_json->0->>'Planning Time')::NUMERIC;
        v_tempo_exec    := (v_plano_json->0->>'Execution Time')::NUMERIC;

        v_custo_startup := (v_plano_json->0->'Plan'->>'Startup Cost')::NUMERIC;
        v_custo_total   := (v_plano_json->0->'Plan'->>'Total Cost')::NUMERIC;

        v_tipo_no       := v_plano_json->0->'Plan'->>'Node Type';

        IF i = 1 THEN
            v_tipo_exec := 'COLD';
        ELSE
            v_tipo_exec := 'WARM';
        END IF;

        INSERT INTO _benchmark_resultados (
            cenario, id_consulta, tipo_execucao, iteracao,
            custo_startup, custo_total,
            tempo_plan_ms, tempo_exec_ms, tempo_total_ms,
            plano_resumo
        ) VALUES (
            p_cenario, p_id_consulta, v_tipo_exec, i,
            v_custo_startup, v_custo_total,
            v_tempo_plan, v_tempo_exec,
            v_tempo_plan + v_tempo_exec,
            v_tipo_no
        );

    END LOOP;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    v_iteracoes INT := 5;  

    q1_union TEXT :=
    'SELECT u.id, u.nome, u.email
     FROM usuarios u
     JOIN pedidos p ON p.usuario_id = u.id
     WHERE p.total > 4000

     UNION

     SELECT u.id, u.nome, u.email
     FROM usuarios u
     JOIN avaliacoes a ON a.usuario_id = u.id
     WHERE a.nota = 5';

    q2_intersect TEXT :=
    'SELECT DISTINCT u.id, u.nome, u.email
     FROM usuarios u
     JOIN pedidos p ON p.usuario_id = u.id
     JOIN itens_pedido ip ON ip.pedido_id = p.id

     INTERSECT

     SELECT DISTINCT u.id, u.nome, u.email
     FROM usuarios u
     JOIN avaliacoes a ON a.usuario_id = u.id';

    q3_except TEXT :=
    'SELECT DISTINCT pr.id, pr.nome
     FROM produtos pr
     JOIN estoque_movimentacao em ON em.produto_id = pr.id
     WHERE em.tipo = ''ENTRADA''

     EXCEPT

     SELECT DISTINCT pr.id, pr.nome
     FROM produtos pr
     JOIN itens_pedido ip ON ip.produto_id = pr.id';

BEGIN

    RAISE NOTICE '';
    RAISE NOTICE '══════════════════════════════════════════════════════════════════════════';
    RAISE NOTICE '  PASSO A — Removendo índices estratégicos...';
    RAISE NOTICE '══════════════════════════════════════════════════════════════════════════';

    DROP INDEX IF EXISTS idx_pedidos_usuario;
    DROP INDEX IF EXISTS idx_itens_pedido_produto;
    DROP INDEX IF EXISTS idx_avaliacoes_usuario;
    DROP INDEX IF EXISTS idx_estoque_produto;

    RAISE NOTICE '    ✗ idx_pedidos_usuario        removido';
    RAISE NOTICE '    ✗ idx_itens_pedido_produto   removido';
    RAISE NOTICE '    ✗ idx_avaliacoes_usuario     removido';
    RAISE NOTICE '    ✗ idx_estoque_produto        removido';

    ANALYZE pedidos;
    ANALYZE itens_pedido;
    ANALYZE avaliacoes;
    ANALYZE estoque_movimentacao;
    ANALYZE usuarios;
    ANALYZE produtos;

    RAISE NOTICE '    ✔ ANALYZE executado em todas as tabelas envolvidas';
    RAISE NOTICE '  Cenário SEM índices preparado.';

    RAISE NOTICE '';
    RAISE NOTICE '══════════════════════════════════════════════════════════════════════════';
    RAISE NOTICE '  PASSO B — Executando benchmark SEM índices (% iterações cada)...', v_iteracoes;
    RAISE NOTICE '══════════════════════════════════════════════════════════════════════════';

    PERFORM benchmark_query('SEM_INDICES', 'Q1_UNION',     q1_union,     v_iteracoes);
    RAISE NOTICE '    ✔ Q1 (UNION)     — % iterações concluídas', v_iteracoes;

    PERFORM benchmark_query('SEM_INDICES', 'Q2_INTERSECT', q2_intersect, v_iteracoes);
    RAISE NOTICE '    ✔ Q2 (INTERSECT) — % iterações concluídas', v_iteracoes;

    PERFORM benchmark_query('SEM_INDICES', 'Q3_EXCEPT',    q3_except,    v_iteracoes);
    RAISE NOTICE '    ✔ Q3 (EXCEPT)    — % iterações concluídas', v_iteracoes;

    RAISE NOTICE '';
    RAISE NOTICE '══════════════════════════════════════════════════════════════════════════';
    RAISE NOTICE '  PASSO C — Criando índices estratégicos...';
    RAISE NOTICE '══════════════════════════════════════════════════════════════════════════';

    CREATE INDEX idx_pedidos_usuario      ON pedidos(usuario_id);
    CREATE INDEX idx_itens_pedido_produto ON itens_pedido(produto_id);
    CREATE INDEX idx_avaliacoes_usuario   ON avaliacoes(usuario_id);
    CREATE INDEX idx_estoque_produto      ON estoque_movimentacao(produto_id);

    RAISE NOTICE '    ✔ idx_pedidos_usuario        ON pedidos(usuario_id)';
    RAISE NOTICE '    ✔ idx_itens_pedido_produto   ON itens_pedido(produto_id)';
    RAISE NOTICE '    ✔ idx_avaliacoes_usuario     ON avaliacoes(usuario_id)';
    RAISE NOTICE '    ✔ idx_estoque_produto        ON estoque_movimentacao(produto_id)';

    ANALYZE pedidos;
    ANALYZE itens_pedido;
    ANALYZE avaliacoes;
    ANALYZE estoque_movimentacao;
    ANALYZE usuarios;
    ANALYZE produtos;

    RAISE NOTICE '    ✔ ANALYZE executado em todas as tabelas envolvidas';
    RAISE NOTICE '  Cenário COM índices preparado.';

    RAISE NOTICE '';
    RAISE NOTICE '══════════════════════════════════════════════════════════════════════════';
    RAISE NOTICE '  PASSO D — Executando benchmark COM índices (% iterações cada)...', v_iteracoes;
    RAISE NOTICE '══════════════════════════════════════════════════════════════════════════';

    PERFORM benchmark_query('COM_INDICES', 'Q1_UNION',     q1_union,     v_iteracoes);
    RAISE NOTICE '    ✔ Q1 (UNION)     — % iterações concluídas', v_iteracoes;

    PERFORM benchmark_query('COM_INDICES', 'Q2_INTERSECT', q2_intersect, v_iteracoes);
    RAISE NOTICE '    ✔ Q2 (INTERSECT) — % iterações concluídas', v_iteracoes;

    PERFORM benchmark_query('COM_INDICES', 'Q3_EXCEPT',    q3_except,    v_iteracoes);
    RAISE NOTICE '    ✔ Q3 (EXCEPT)    — % iterações concluídas', v_iteracoes;

    RAISE NOTICE '';
    RAISE NOTICE '══════════════════════════════════════════════════════════════════════════';
    RAISE NOTICE '  PASSOS A-D CONCLUÍDOS — Gerando relatórios (Seção 3)...';
    RAISE NOTICE '══════════════════════════════════════════════════════════════════════════';

END $$;

SELECT '═══ RELATÓRIO 1 — Medições Individuais ═══' AS "Relatorio";

SELECT
    cenario                                 AS "Cenário",
    id_consulta                             AS "Query",
    tipo_execucao                           AS "Tipo",
    iteracao                                AS "Iter.",
    plano_resumo                            AS "Nó Raiz",
    ROUND(custo_startup, 2)                 AS "Custo Startup",
    ROUND(custo_total, 2)                   AS "Custo Total",
    ROUND(tempo_plan_ms, 3)                 AS "Plan (ms)",
    ROUND(tempo_exec_ms, 3)                 AS "Exec (ms)",
    ROUND(tempo_total_ms, 3)                AS "Total (ms)"
FROM _benchmark_resultados
ORDER BY id_consulta, cenario DESC, iteracao;

SELECT '═══ RELATÓRIO 2 — Estatísticas Agregadas ═══' AS "Relatorio";

SELECT
    cenario                                 AS "Cenário",
    id_consulta                             AS "Query",
    tipo_execucao                           AS "Tipo",
    COUNT(*)                                AS "N",
    ROUND(MIN(custo_total), 2)              AS "Custo Total",
    ROUND(MIN(tempo_plan_ms), 3)            AS "Plan Min (ms)",
    ROUND(AVG(tempo_plan_ms), 3)            AS "Plan Média (ms)",
    ROUND(MAX(tempo_plan_ms), 3)            AS "Plan Max (ms)",
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY tempo_plan_ms), 3)
                                            AS "Plan Mediana (ms)",
    ROUND(MIN(tempo_exec_ms), 3)            AS "Exec Min (ms)",
    ROUND(AVG(tempo_exec_ms), 3)            AS "Exec Média (ms)",
    ROUND(MAX(tempo_exec_ms), 3)            AS "Exec Max (ms)",
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY tempo_exec_ms), 3)
                                            AS "Exec Mediana (ms)",
    ROUND(MIN(tempo_total_ms), 3)           AS "Total Min (ms)",
    ROUND(AVG(tempo_total_ms), 3)           AS "Total Média (ms)",
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY tempo_total_ms), 3)
                                            AS "Total Mediana (ms)"
FROM _benchmark_resultados
GROUP BY cenario, id_consulta, tipo_execucao
ORDER BY id_consulta, tipo_execucao, cenario DESC;

SELECT '═══ RELATÓRIO 3 — Antes vs Depois (Warm) ═══' AS "Relatorio";

WITH medianas AS (
    SELECT
        cenario,
        id_consulta,
        ROUND(MIN(custo_startup), 2)    AS custo_startup,
        ROUND(MIN(custo_total), 2)      AS custo_total,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY tempo_plan_ms), 3) AS med_plan,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY tempo_exec_ms), 3) AS med_exec,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY tempo_total_ms), 3) AS med_total
    FROM _benchmark_resultados
    WHERE tipo_execucao = 'WARM'
    GROUP BY cenario, id_consulta
)
SELECT
    a.id_consulta                           AS "Query",
    CASE a.id_consulta
        WHEN 'Q1_UNION'     THEN 'UNION + JOINs'
        WHEN 'Q2_INTERSECT' THEN 'INTERSECT + JOINs'
        WHEN 'Q3_EXCEPT'    THEN 'EXCEPT + JOINs'
    END                                     AS "Operador",

    a.custo_startup                         AS "Custo Startup (Antes)",
    a.custo_total                           AS "Custo Total (Antes)",
    d.custo_startup                         AS "Custo Startup (Depois)",
    d.custo_total                           AS "Custo Total (Depois)",

    a.med_plan                              AS "Plan Antes (ms)",
    d.med_plan                              AS "Plan Depois (ms)",

    a.med_exec                              AS "Exec Antes (ms)",
    d.med_exec                              AS "Exec Depois (ms)",

    a.med_total                             AS "Total Antes (ms)",
    d.med_total                             AS "Total Depois (ms)",

    ROUND(
        CASE WHEN a.custo_total > 0
             THEN ((a.custo_total - d.custo_total) / a.custo_total) * 100
             ELSE 0
        END, 2
    )                                       AS "Redução Custo (%)",

    ROUND(
        CASE WHEN a.med_exec > 0
             THEN ((a.med_exec - d.med_exec) / a.med_exec) * 100
             ELSE 0
        END, 2
    )                                       AS "Redução Exec (%)",

    ROUND(a.med_total - d.med_total, 3)     AS "Ganho Total (ms)",

    ROUND(
        CASE WHEN d.med_total > 0
             THEN a.med_total / d.med_total
             ELSE 0
        END, 2
    )                                       AS "Speedup (x)"

FROM medianas a
JOIN medianas d ON a.id_consulta = d.id_consulta
WHERE a.cenario = 'SEM_INDICES'
  AND d.cenario = 'COM_INDICES'
ORDER BY a.id_consulta;

SELECT '═══ RELATÓRIO 4 — Cold Start (1a Execucao) ═══' AS "Relatorio";

SELECT
    a.id_consulta                           AS "Query",
    CASE a.id_consulta
        WHEN 'Q1_UNION'     THEN 'UNION + JOINs'
        WHEN 'Q2_INTERSECT' THEN 'INTERSECT + JOINs'
        WHEN 'Q3_EXCEPT'    THEN 'EXCEPT + JOINs'
    END                                     AS "Operador",

    ROUND(a.custo_total, 2)                 AS "Custo Total (Antes)",
    ROUND(d.custo_total, 2)                 AS "Custo Total (Depois)",

    ROUND(a.tempo_plan_ms, 3)               AS "Plan Antes (ms)",
    ROUND(d.tempo_plan_ms, 3)               AS "Plan Depois (ms)",

    ROUND(a.tempo_exec_ms, 3)               AS "Exec Antes (ms)",
    ROUND(d.tempo_exec_ms, 3)               AS "Exec Depois (ms)",

    ROUND(a.tempo_total_ms, 3)              AS "Total Antes (ms)",
    ROUND(d.tempo_total_ms, 3)              AS "Total Depois (ms)",

    ROUND(
        CASE WHEN a.tempo_exec_ms > 0
             THEN ((a.tempo_exec_ms - d.tempo_exec_ms) / a.tempo_exec_ms) * 100
             ELSE 0
        END, 2
    )                                       AS "Redução Exec (%)",

    a.plano_resumo                          AS "Plano Antes",
    d.plano_resumo                          AS "Plano Depois"

FROM _benchmark_resultados a
JOIN _benchmark_resultados d
    ON  a.id_consulta   = d.id_consulta
    AND a.tipo_execucao = 'COLD'
    AND d.tipo_execucao = 'COLD'
WHERE a.cenario = 'SEM_INDICES'
  AND d.cenario = 'COM_INDICES'
ORDER BY a.id_consulta;

SELECT '═══ RELATÓRIO 5 — Impacto do Cache ═══' AS "Relatorio";

WITH cold AS (
    SELECT cenario, id_consulta, tempo_exec_ms AS exec_cold, tempo_total_ms AS total_cold
    FROM _benchmark_resultados
    WHERE tipo_execucao = 'COLD'
),
warm_med AS (
    SELECT
        cenario, id_consulta,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY tempo_exec_ms), 3) AS exec_warm,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY tempo_total_ms), 3) AS total_warm
    FROM _benchmark_resultados
    WHERE tipo_execucao = 'WARM'
    GROUP BY cenario, id_consulta
)
SELECT
    c.cenario                               AS "Cenário",
    c.id_consulta                           AS "Query",
    ROUND(c.exec_cold, 3)                   AS "Exec Cold (ms)",
    w.exec_warm                             AS "Exec Warm Med. (ms)",
    ROUND(c.exec_cold - w.exec_warm, 3)     AS "Ganho Cache (ms)",
    ROUND(
        CASE WHEN c.exec_cold > 0
             THEN ((c.exec_cold - w.exec_warm) / c.exec_cold) * 100
             ELSE 0
        END, 2
    )                                       AS "Redução por Cache (%)"
FROM cold c
JOIN warm_med w ON c.cenario = w.cenario AND c.id_consulta = w.id_consulta
ORDER BY c.id_consulta, c.cenario DESC;
