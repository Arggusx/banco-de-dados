CREATE TABLE categorias (
    id    SERIAL PRIMARY KEY,
    nome  VARCHAR(80)
);

CREATE TABLE marcas (
    id    SERIAL PRIMARY KEY,
    nome  VARCHAR(80)
);

CREATE TABLE metodos_pagamento (
    id        SERIAL PRIMARY KEY,
    descricao VARCHAR(80)
);

CREATE TABLE status_pedido (
    id        SERIAL PRIMARY KEY,
    descricao VARCHAR(60)
);

CREATE TABLE transportadoras (
    id            SERIAL PRIMARY KEY,
    nome_fantasia VARCHAR(150),
    cnpj          VARCHAR(20)
);

CREATE TABLE fornecedores (
    id      SERIAL PRIMARY KEY,
    nome    VARCHAR(150),
    contato VARCHAR(100)
);

CREATE TABLE departamentos (
    id    SERIAL PRIMARY KEY,
    nome  VARCHAR(80)
);

CREATE TABLE perfis_acesso (
    id         SERIAL PRIMARY KEY,
    nome_cargo VARCHAR(80)
);

CREATE TABLE paises (
    id    SERIAL PRIMARY KEY,
    nome  VARCHAR(80),
    sigla VARCHAR(5)
);

CREATE TABLE cupons (
    id         SERIAL PRIMARY KEY,
    codigo     VARCHAR(30),
    percentual DECIMAL(5,2)
);

CREATE TABLE usuarios (
    id        SERIAL PRIMARY KEY,
    perfil_id INT REFERENCES perfis_acesso(id),
    nome      VARCHAR(200),
    email     VARCHAR(250) UNIQUE,
    senha     VARCHAR(255)
);

CREATE TABLE produtos (
    id            SERIAL PRIMARY KEY,
    categoria_id  INT REFERENCES categorias(id),
    marca_id      INT REFERENCES marcas(id),
    fornecedor_id INT REFERENCES fornecedores(id),
    nome          VARCHAR(200),
    preco         DECIMAL(10,2)
);

CREATE TABLE enderecos (
    id         SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id),
    pais_id    INT REFERENCES paises(id),
    rua        VARCHAR(300),
    cidade     VARCHAR(150)
);

CREATE TABLE pedidos (
    id                SERIAL PRIMARY KEY,
    usuario_id        INT REFERENCES usuarios(id),
    status_id         INT REFERENCES status_pedido(id),
    transportadora_id INT REFERENCES transportadoras(id),
    data_pedido       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total             DECIMAL(10,2)
);

CREATE TABLE itens_pedido (
    id          SERIAL PRIMARY KEY,
    pedido_id   INT REFERENCES pedidos(id),
    produto_id  INT REFERENCES produtos(id),
    quantidade  INT
);

CREATE TABLE pagamentos (
    id        SERIAL PRIMARY KEY,
    pedido_id INT REFERENCES pedidos(id),
    metodo_id INT REFERENCES metodos_pagamento(id),
    valor     DECIMAL(10,2)
);

CREATE TABLE avaliacoes (
    id          SERIAL PRIMARY KEY,
    usuario_id  INT REFERENCES usuarios(id),
    produto_id  INT REFERENCES produtos(id),
    nota        INT CHECK (nota BETWEEN 1 AND 5),
    comentario  TEXT
);

CREATE TABLE estoque_movimentacao (
    id          SERIAL PRIMARY KEY,
    produto_id  INT REFERENCES produtos(id),
    tipo        VARCHAR(10),   
    quantidade  INT
);

CREATE TABLE log_acessos (
    id         SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id),
    ip         VARCHAR(45),
    data_hora  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cupons_uso (
    id                SERIAL PRIMARY KEY,
    pedido_id         INT REFERENCES pedidos(id),
    cupom_id          INT REFERENCES cupons(id),
    desconto_aplicado DECIMAL(10,2)
);

CREATE INDEX idx_usuarios_perfil        ON usuarios(perfil_id);
CREATE INDEX idx_produtos_categoria     ON produtos(categoria_id);
CREATE INDEX idx_produtos_marca         ON produtos(marca_id);
CREATE INDEX idx_produtos_fornecedor    ON produtos(fornecedor_id);
CREATE INDEX idx_enderecos_usuario      ON enderecos(usuario_id);
CREATE INDEX idx_enderecos_pais         ON enderecos(pais_id);
CREATE INDEX idx_pedidos_usuario        ON pedidos(usuario_id);
CREATE INDEX idx_pedidos_status         ON pedidos(status_id);
CREATE INDEX idx_pedidos_transportadora ON pedidos(transportadora_id);
CREATE INDEX idx_itens_pedido_pedido    ON itens_pedido(pedido_id);
CREATE INDEX idx_itens_pedido_produto   ON itens_pedido(produto_id);
CREATE INDEX idx_pagamentos_pedido      ON pagamentos(pedido_id);
CREATE INDEX idx_pagamentos_metodo      ON pagamentos(metodo_id);
CREATE INDEX idx_avaliacoes_usuario     ON avaliacoes(usuario_id);
CREATE INDEX idx_avaliacoes_produto     ON avaliacoes(produto_id);
CREATE INDEX idx_estoque_produto        ON estoque_movimentacao(produto_id);
CREATE INDEX idx_log_acessos_usuario    ON log_acessos(usuario_id);
CREATE INDEX idx_cupons_uso_pedido      ON cupons_uso(pedido_id);
CREATE INDEX idx_cupons_uso_cupom       ON cupons_uso(cupom_id);
