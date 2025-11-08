-- Migration: 002 - Add Slug to Product
-- Description: Adiciona campo slug para URLs amigáveis nos produtos
-- Created: 2024-11-07
-- Author: Mova Design

-- Adicionar coluna slug
ALTER TABLE produto 
ADD COLUMN slug VARCHAR(255);

-- Criar índice único para slug
CREATE UNIQUE INDEX idx_produto_slug ON produto(slug);

-- Adicionar comentário
COMMENT ON COLUMN produto.slug IS 'URL amigável do produto (ex: tenis-nike-revolution-5)';

-- Popular slugs existentes (exemplo)
UPDATE produto 
SET slug = LOWER(REGEXP_REPLACE(nome, '[^a-zA-Z0-9]+', '-', 'g'))
WHERE slug IS NULL;

-- Tornar slug obrigatório após popular
ALTER TABLE produto 
ALTER COLUMN slug SET NOT NULL;

