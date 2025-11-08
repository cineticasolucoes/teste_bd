-- Migration: 001 - Create Initial Schema
-- Description: Cria as tabelas base do sistema de e-commerce
-- Created: 2024-11-07
-- Author: Mova Design

-- ==============================================
-- TABELA: Usuario
-- ==============================================
CREATE TABLE usuario (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    senha_hash VARCHAR(255) NOT NULL,
    cpf VARCHAR(14) UNIQUE,
    data_nascimento DATE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Índices para Usuario
CREATE UNIQUE INDEX idx_usuario_email ON usuario(email);
CREATE UNIQUE INDEX idx_usuario_cpf ON usuario(cpf) WHERE cpf IS NOT NULL;

-- Comentários
COMMENT ON TABLE usuario IS 'Armazena informações dos usuários do sistema';
COMMENT ON COLUMN usuario.senha_hash IS 'Hash da senha usando bcrypt';

-- ==============================================
-- TABELA: Endereco
-- ==============================================
CREATE TABLE endereco (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL,
    nome VARCHAR(100) NOT NULL,
    cep VARCHAR(9) NOT NULL,
    logradouro VARCHAR(255) NOT NULL,
    numero VARCHAR(20) NOT NULL,
    complemento VARCHAR(255),
    bairro VARCHAR(100) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    estado VARCHAR(2) NOT NULL,
    padrao BOOLEAN NOT NULL DEFAULT FALSE,
    criado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    
    CONSTRAINT fk_endereco_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuario(id)
        ON DELETE CASCADE
);

-- Índices para Endereco
CREATE INDEX idx_endereco_usuario ON endereco(usuario_id);

COMMENT ON TABLE endereco IS 'Endereços de entrega dos usuários';

-- ==============================================
-- TABELA: Categoria
-- ==============================================
CREATE TABLE categoria (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT,
    ativa BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE categoria IS 'Categorias de produtos';

-- ==============================================
-- TABELA: Produto
-- ==============================================
CREATE TABLE produto (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    categoria_id UUID NOT NULL,
    nome VARCHAR(255) NOT NULL,
    descricao TEXT,
    preco DECIMAL(10, 2) NOT NULL,
    estoque INTEGER NOT NULL DEFAULT 0,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    
    CONSTRAINT fk_produto_categoria
        FOREIGN KEY (categoria_id)
        REFERENCES categoria(id)
        ON DELETE RESTRICT,
    
    CONSTRAINT chk_preco_positivo
        CHECK (preco >= 0),
    
    CONSTRAINT chk_estoque_positivo
        CHECK (estoque >= 0)
);

-- Índices para Produto
CREATE INDEX idx_produto_categoria ON produto(categoria_id);
CREATE INDEX idx_produto_ativo ON produto(ativo);

COMMENT ON TABLE produto IS 'Produtos disponíveis para venda';
COMMENT ON COLUMN produto.preco IS 'Preço em reais';

-- ==============================================
-- TABELA: Pedido
-- ==============================================
CREATE TABLE pedido (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL,
    endereco_id UUID NOT NULL,
    numero_pedido VARCHAR(20) NOT NULL UNIQUE,
    status VARCHAR(50) NOT NULL DEFAULT 'pendente',
    subtotal DECIMAL(10, 2) NOT NULL,
    desconto DECIMAL(10, 2) NOT NULL DEFAULT 0,
    frete DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total DECIMAL(10, 2) NOT NULL,
    criado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    
    CONSTRAINT fk_pedido_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuario(id)
        ON DELETE RESTRICT,
    
    CONSTRAINT fk_pedido_endereco
        FOREIGN KEY (endereco_id)
        REFERENCES endereco(id)
        ON DELETE RESTRICT,
    
    CONSTRAINT chk_status_valido
        CHECK (status IN ('pendente', 'pago', 'separado', 'enviado', 'entregue', 'cancelado')),
    
    CONSTRAINT chk_valores_positivos
        CHECK (subtotal >= 0 AND desconto >= 0 AND frete >= 0 AND total >= 0)
);

-- Índices para Pedido
CREATE UNIQUE INDEX idx_pedido_numero ON pedido(numero_pedido);
CREATE INDEX idx_pedido_usuario ON pedido(usuario_id);
CREATE INDEX idx_pedido_status ON pedido(status);
CREATE INDEX idx_pedido_criado ON pedido(criado_em);

COMMENT ON TABLE pedido IS 'Pedidos realizados pelos usuários';

-- ==============================================
-- TABELA: ItemPedido
-- ==============================================
CREATE TABLE item_pedido (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id UUID NOT NULL,
    produto_id UUID NOT NULL,
    quantidade INTEGER NOT NULL,
    preco_unitario DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    criado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    
    CONSTRAINT fk_item_pedido
        FOREIGN KEY (pedido_id)
        REFERENCES pedido(id)
        ON DELETE CASCADE,
    
    CONSTRAINT fk_item_produto
        FOREIGN KEY (produto_id)
        REFERENCES produto(id)
        ON DELETE RESTRICT,
    
    CONSTRAINT chk_quantidade_positiva
        CHECK (quantidade > 0),
    
    CONSTRAINT chk_preco_positivo
        CHECK (preco_unitario >= 0 AND subtotal >= 0)
);

-- Índices para ItemPedido
CREATE INDEX idx_item_pedido ON item_pedido(pedido_id);
CREATE INDEX idx_item_produto ON item_pedido(produto_id);

COMMENT ON TABLE item_pedido IS 'Itens que compõem cada pedido';
COMMENT ON COLUMN item_pedido.preco_unitario IS 'Preço do produto no momento da compra';

-- ==============================================
-- TRIGGERS
-- ==============================================

-- Trigger para atualizar automaticamente updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_usuario_updated_at BEFORE UPDATE ON usuario
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_produto_updated_at BEFORE UPDATE ON produto
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pedido_updated_at BEFORE UPDATE ON pedido
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==============================================
-- FIM DA MIGRATION
-- ==============================================

