INSERT INTO categorias (nome)
SELECT 'Categoria ' || i
FROM generate_series(1, 5000) AS i;

INSERT INTO marcas (nome)
SELECT 'Marca ' || i
FROM generate_series(1, 5000) AS i;

INSERT INTO metodos_pagamento (descricao)
SELECT 'Metodo ' || i
FROM generate_series(1, 5000) AS i;

INSERT INTO status_pedido (descricao)
SELECT 'Status ' || i
FROM generate_series(1, 5000) AS i;

INSERT INTO transportadoras (nome_fantasia, cnpj)
SELECT
    'Transportadora ' || i,
    LPAD(i::TEXT, 14, '0')          
FROM generate_series(1, 5000) AS i;

INSERT INTO fornecedores (nome, contato)
SELECT
    'Fornecedor ' || i,
    'contato@fornecedor' || i || '.com.br'
FROM generate_series(1, 5000) AS i;

INSERT INTO departamentos (nome)
SELECT 'Departamento ' || i
FROM generate_series(1, 5000) AS i;

INSERT INTO perfis_acesso (nome_cargo)
SELECT 'Cargo ' || i
FROM generate_series(1, 5000) AS i;

INSERT INTO paises (nome, sigla)
SELECT
    'Pais ' || i,
    'P' || i
FROM generate_series(1, 5000) AS i;

INSERT INTO cupons (codigo, percentual)
SELECT
    'CUPOM' || LPAD(i::TEXT, 4, '0'),
    (random() * 50)::NUMERIC(5,2)
FROM generate_series(1, 5000) AS i;

SELECT 'PARTE 1 CONCLUÍDA' AS status,
       (SELECT COUNT(*) FROM categorias)        AS categorias,
       (SELECT COUNT(*) FROM marcas)             AS marcas,
       (SELECT COUNT(*) FROM metodos_pagamento)  AS metodos_pagamento,
       (SELECT COUNT(*) FROM status_pedido)      AS status_pedido,
       (SELECT COUNT(*) FROM transportadoras)    AS transportadoras,
       (SELECT COUNT(*) FROM fornecedores)       AS fornecedores,
       (SELECT COUNT(*) FROM departamentos)      AS departamentos,
       (SELECT COUNT(*) FROM perfis_acesso)      AS perfis_acesso,
       (SELECT COUNT(*) FROM paises)             AS paises,
       (SELECT COUNT(*) FROM cupons)             AS cupons;
