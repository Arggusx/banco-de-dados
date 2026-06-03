INSERT INTO produtos (categoria_id, marca_id, fornecedor_id, nome, preco)
SELECT
    floor(random() * 5000 + 1)::INT,       
    floor(random() * 5000 + 1)::INT,       
    floor(random() * 5000 + 1)::INT,       
    'Produto ' || i,
    (random() * 4999.99 + 0.01)::NUMERIC(10,2)
FROM generate_series(1, 25000) AS i;

INSERT INTO pedidos (usuario_id, status_id, transportadora_id, data_pedido, total)
SELECT
    floor(random() * 25000 + 1)::INT,       
    floor(random() * 5000 + 1)::INT,       
    floor(random() * 5000 + 1)::INT,       
    CURRENT_TIMESTAMP - (random() * 365)::INT * INTERVAL '1 day',  
    (random() * 24999.99 + 0.01)::NUMERIC(10,2)
FROM generate_series(1, 25000) AS i;

INSERT INTO itens_pedido (pedido_id, produto_id, quantidade)
SELECT
    floor(random() * 25000 + 1)::INT,       
    floor(random() * 25000 + 1)::INT,       
    floor(random() * 50 + 1)::INT          
FROM generate_series(1, 25000) AS i;

INSERT INTO pagamentos (pedido_id, metodo_id, valor)
SELECT
    floor(random() * 25000 + 1)::INT,       
    floor(random() * 5000 + 1)::INT,       
    (random() * 24999.99 + 0.01)::NUMERIC(10,2)
FROM generate_series(1, 25000) AS i;

INSERT INTO avaliacoes (usuario_id, produto_id, nota, comentario)
SELECT
    floor(random() * 25000 + 1)::INT,       
    floor(random() * 25000 + 1)::INT,       
    floor(random() * 5 + 1)::INT,          
    CASE floor(random() * 5)::INT
        WHEN 0 THEN 'Excelente produto, recomendo!'
        WHEN 1 THEN 'Muito bom, atendeu minhas expectativas.'
        WHEN 2 THEN 'Produto razoável, poderia melhorar.'
        WHEN 3 THEN 'Bom custo-benefício.'
        ELSE        'Entrega rápida, produto de qualidade.'
    END
FROM generate_series(1, 25000) AS i;

INSERT INTO estoque_movimentacao (produto_id, tipo, quantidade)
SELECT
    floor(random() * 25000 + 1)::INT,       
    CASE WHEN random() < 0.7
         THEN 'ENTRADA'
         ELSE 'SAIDA'
    END,
    floor(random() * 500 + 1)::INT         
FROM generate_series(1, 25000) AS i;

INSERT INTO log_acessos (usuario_id, ip, data_hora)
SELECT
    floor(random() * 25000 + 1)::INT,       
    (floor(random() * 223 + 1)::INT || '.' ||
     floor(random() * 256)::INT     || '.' ||
     floor(random() * 256)::INT     || '.' ||
     floor(random() * 256)::INT)::VARCHAR,  
    CURRENT_TIMESTAMP - (random() * 365)::INT * INTERVAL '1 day'
        + (random() * 86400)::INT * INTERVAL '1 second'
FROM generate_series(1, 25000) AS i;

INSERT INTO cupons_uso (pedido_id, cupom_id, desconto_aplicado)
SELECT
    floor(random() * 25000 + 1)::INT,       
    floor(random() * 5000 + 1)::INT,       
    (random() * 499.99 + 0.01)::NUMERIC(10,2)
FROM generate_series(1, 25000) AS i;

SELECT '═══ VALIDAÇÃO FINAL ═══' AS info;

SELECT
    (SELECT COUNT(*) FROM categorias)            AS categorias,
    (SELECT COUNT(*) FROM marcas)                AS marcas,
    (SELECT COUNT(*) FROM metodos_pagamento)     AS metodos_pagamento,
    (SELECT COUNT(*) FROM status_pedido)         AS status_pedido,
    (SELECT COUNT(*) FROM transportadoras)       AS transportadoras,
    (SELECT COUNT(*) FROM fornecedores)          AS fornecedores,
    (SELECT COUNT(*) FROM departamentos)         AS departamentos,
    (SELECT COUNT(*) FROM perfis_acesso)         AS perfis_acesso,
    (SELECT COUNT(*) FROM paises)                AS paises,
    (SELECT COUNT(*) FROM cupons)                AS cupons,
    (SELECT COUNT(*) FROM usuarios)              AS usuarios,
    (SELECT COUNT(*) FROM enderecos)             AS enderecos,
    (SELECT COUNT(*) FROM produtos)              AS produtos,
    (SELECT COUNT(*) FROM pedidos)               AS pedidos,
    (SELECT COUNT(*) FROM itens_pedido)          AS itens_pedido,
    (SELECT COUNT(*) FROM pagamentos)            AS pagamentos,
    (SELECT COUNT(*) FROM avaliacoes)            AS avaliacoes,
    (SELECT COUNT(*) FROM estoque_movimentacao)  AS estoque_mov,
    (SELECT COUNT(*) FROM log_acessos)           AS log_acessos,
    (SELECT COUNT(*) FROM cupons_uso)            AS cupons_uso;

SELECT
    'TOTAL GERAL' AS resumo,
    (SELECT COUNT(*) FROM categorias) +
    (SELECT COUNT(*) FROM marcas) +
    (SELECT COUNT(*) FROM metodos_pagamento) +
    (SELECT COUNT(*) FROM status_pedido) +
    (SELECT COUNT(*) FROM transportadoras) +
    (SELECT COUNT(*) FROM fornecedores) +
    (SELECT COUNT(*) FROM departamentos) +
    (SELECT COUNT(*) FROM perfis_acesso) +
    (SELECT COUNT(*) FROM paises) +
    (SELECT COUNT(*) FROM cupons) +
    (SELECT COUNT(*) FROM usuarios) +
    (SELECT COUNT(*) FROM enderecos) +
    (SELECT COUNT(*) FROM produtos) +
    (SELECT COUNT(*) FROM pedidos) +
    (SELECT COUNT(*) FROM itens_pedido) +
    (SELECT COUNT(*) FROM pagamentos) +
    (SELECT COUNT(*) FROM avaliacoes) +
    (SELECT COUNT(*) FROM estoque_movimentacao) +
    (SELECT COUNT(*) FROM log_acessos) +
    (SELECT COUNT(*) FROM cupons_uso) AS total_registros;

SELECT
    p.id              AS pedido_id,
    u.nome            AS cliente,
    u.email           AS email_cliente,
    pr.nome           AS produto,
    ip.quantidade     AS qtd,
    t.nome_fantasia   AS transportadora,
    s.descricao       AS status,
    pg.valor          AS valor_pago,
    mp.descricao      AS metodo_pagamento
FROM pedidos p
JOIN usuarios u            ON p.usuario_id        = u.id
JOIN itens_pedido ip       ON ip.pedido_id         = p.id
JOIN produtos pr           ON ip.produto_id        = pr.id
JOIN transportadoras t     ON p.transportadora_id  = t.id
JOIN status_pedido s       ON p.status_id          = s.id
LEFT JOIN pagamentos pg    ON pg.pedido_id         = p.id
LEFT JOIN metodos_pagamento mp ON pg.metodo_id     = mp.id
LIMIT 10;
