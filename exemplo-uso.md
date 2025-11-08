# Exemplos de Uso - Database as Code

Este documento mostra exemplos práticos de como usar o approach de Database as Code no dia a dia.

## 📝 Cenário 1: Adicionando uma Nova Feature

### Requisito
*"Precisamos adicionar avaliações (reviews) aos produtos"*

### Passo 1: Atualizar o `schema.yaml`

Adicionar no final do arquivo:

```yaml
  AvaliacaoProduto:
    description: Avaliações dos produtos feitas pelos usuários
    fields:
      id:
        type: uuid
        primaryKey: true
        nullable: false
      
      produto_id:
        type: uuid
        nullable: false
        foreignKey:
          references: Produto.id
          onDelete: cascade
      
      usuario_id:
        type: uuid
        nullable: false
        foreignKey:
          references: Usuario.id
          onDelete: cascade
      
      nota:
        type: integer
        nullable: false
        description: Nota de 1 a 5
      
      comentario:
        type: text
        nullable: true
      
      criado_em:
        type: timestamp
        nullable: false
        default: now()
    
    indexes:
      - name: idx_avaliacao_produto
        fields: [produto_id]
      
      - name: idx_avaliacao_usuario
        fields: [usuario_id]
```

### Passo 2: Criar a Migration

Criar arquivo: `migrations/003_create_avaliacoes.sql`

```sql
-- Migration: 003 - Create Product Reviews
-- Description: Adiciona tabela de avaliações de produtos
-- Created: 2024-11-08

CREATE TABLE avaliacao_produto (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id UUID NOT NULL,
    usuario_id UUID NOT NULL,
    nota INTEGER NOT NULL,
    comentario TEXT,
    criado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    
    CONSTRAINT fk_avaliacao_produto
        FOREIGN KEY (produto_id)
        REFERENCES produto(id)
        ON DELETE CASCADE,
    
    CONSTRAINT fk_avaliacao_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuario(id)
        ON DELETE CASCADE,
    
    CONSTRAINT chk_nota_valida
        CHECK (nota >= 1 AND nota <= 5),
    
    -- Usuário só pode avaliar produto uma vez
    CONSTRAINT uk_usuario_produto
        UNIQUE (usuario_id, produto_id)
);

CREATE INDEX idx_avaliacao_produto ON avaliacao_produto(produto_id);
CREATE INDEX idx_avaliacao_usuario ON avaliacao_produto(usuario_id);

COMMENT ON TABLE avaliacao_produto IS 'Avaliações dos produtos';
COMMENT ON COLUMN avaliacao_produto.nota IS 'Nota de 1 a 5';
```

### Passo 3: Commitar

```bash
git add schema.yaml migrations/003_create_avaliacoes.sql
git commit -m "feat: adiciona sistema de avaliações de produtos"
git push origin feature/avaliacoes
```

### Passo 4: Code Review

Outros desenvolvedores podem revisar:
- A estrutura da tabela está correta?
- Os índices são apropriados?
- As constraints fazem sentido?
- A documentação está clara?

### Passo 5: Aplicar no Banco

```bash
# Desenvolvimento
psql -U postgres -d ecommerce_dev < migrations/003_create_avaliacoes.sql

# Produção (após aprovação)
psql -U postgres -d ecommerce_prod < migrations/003_create_avaliacoes.sql
```

---

## 🔄 Cenário 2: Modificando uma Estrutura Existente

### Requisito
*"Precisamos aumentar o tamanho máximo do nome do produto"*

### Passo 1: Atualizar `schema.yaml`

```yaml
Produto:
  fields:
    nome:
      type: varchar
      length: 500  # Era 255, agora 500
      nullable: false
```

### Passo 2: Criar Migration

`migrations/004_increase_produto_nome.sql`

```sql
-- Migration: 004 - Increase Product Name Length
-- Description: Aumenta tamanho do nome do produto de 255 para 500 chars
-- Created: 2024-11-08

ALTER TABLE produto 
ALTER COLUMN nome TYPE VARCHAR(500);
```

### Passo 3: Testar Rollback (se necessário)

```sql
-- Rollback (migrations/004_increase_produto_nome_down.sql)
ALTER TABLE produto 
ALTER COLUMN nome TYPE VARCHAR(255);
```

---

## 🗑️ Cenário 3: Removendo uma Coluna

### Requisito
*"O campo 'complemento' no endereço não está sendo usado"*

### Estratégia: Remoção Segura (3 fases)

#### Fase 1: Tornar opcional e deprecar

`migrations/005_deprecate_endereco_complemento.sql`

```sql
-- Migration: 005 - Deprecate Complemento
-- Description: Marca campo complemento como deprecated
-- Created: 2024-11-08

COMMENT ON COLUMN endereco.complemento IS 
'DEPRECATED: Este campo será removido na versão 2.0';
```

Atualizar `schema.yaml`:
```yaml
complemento:
  type: varchar
  length: 255
  nullable: true
  deprecated: true  # Flag para indicar que será removido
```

#### Fase 2: Remover das aplicações (algumas sprints depois)
Garantir que nenhum código usa mais o campo.

#### Fase 3: Remover do banco

`migrations/006_remove_endereco_complemento.sql`

```sql
-- Migration: 006 - Remove Complemento
-- Description: Remove campo complemento
-- Created: 2024-12-01

ALTER TABLE endereco 
DROP COLUMN complemento;
```

Remover do `schema.yaml`.

---

## 🔀 Cenário 4: Trabalhando em Branches

### Situação
Dois desenvolvedores trabalhando em features diferentes:

**Dev A:** Adiciona campo `peso` ao produto
**Dev B:** Adiciona campo `dimensoes` ao produto

### Dev A cria:
```
migrations/003_add_produto_peso.sql
```

### Dev B cria (no branch dele):
```
migrations/003_add_produto_dimensoes.sql  # ❌ Conflito de número!
```

### Solução: Ao fazer merge

Dev B renomeia sua migration:
```bash
git mv migrations/003_add_produto_dimensoes.sql \
       migrations/004_add_produto_dimensoes.sql
```

Atualiza o número dentro do arquivo também.

---

## 🚀 Cenário 5: Deploy em Produção

### Checklist antes do Deploy

```bash
# 1. Verificar quais migrations faltam aplicar
psql -U postgres -d ecommerce_prod -c "SELECT * FROM schema_migrations"

# 2. Fazer backup
pg_dump -U postgres ecommerce_prod > backup_$(date +%Y%m%d).sql

# 3. Testar migrations em staging
psql -U postgres -d ecommerce_staging < migrations/003_create_avaliacoes.sql

# 4. Validar que aplicou corretamente
psql -U postgres -d ecommerce_staging -c "\d avaliacao_produto"

# 5. Aplicar em produção (em janela de manutenção)
psql -U postgres -d ecommerce_prod < migrations/003_create_avaliacoes.sql

# 6. Validar
psql -U postgres -d ecommerce_prod -c "\d avaliacao_produto"

# 7. Registrar migration aplicada
psql -U postgres -d ecommerce_prod -c \
  "INSERT INTO schema_migrations (version, applied_at) VALUES (3, NOW())"
```

---

## 🔍 Cenário 6: Auditoria e Histórico

### Ver histórico de mudanças no schema

```bash
# Ver todas as mudanças no schema
git log --oneline schema.yaml

# Ver diff de uma mudança específica
git show abc123f schema.yaml

# Ver quem mudou e quando
git blame schema.yaml
```

### Reverter uma mudança (se necessário)

```bash
# Voltar schema.yaml para versão anterior
git checkout HEAD~1 -- schema.yaml

# Criar migration de rollback
# migrations/007_revert_feature_x.sql
```

---

## 📊 Cenário 7: Gerando Documentação

### Usando o schema.yaml como fonte

```bash
# Gerar documentação em Markdown
mova-design docs schema.yaml > DATABASE_DOCS.md

# Gerar diagrama ER visual
mova-design diagram schema.yaml > er-diagram.svg

# Gerar script de criação completo
mova-design generate-sql schema.yaml > full-schema.sql
```

---

## ✅ Cenário 8: Validação Automática (CI/CD)

### GitHub Actions / GitLab CI

```yaml
# .github/workflows/database-validation.yml
name: Database Schema Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Validate YAML Syntax
        run: yamllint schema.yaml
      
      - name: Check Migration Numbers
        run: |
          # Verifica se não há números duplicados
          ls migrations/*.sql | sed 's/[^0-9]//g' | sort | uniq -d
      
      - name: Test Migrations
        run: |
          docker run -d -e POSTGRES_PASSWORD=test postgres:15
          sleep 5
          # Aplicar todas as migrations
          for f in migrations/*.sql; do
            psql -h localhost -U postgres < $f
          done
      
      - name: Validate Schema Consistency
        run: |
          # Gerar SQL do YAML e comparar com migrations
          mova-design generate-sql schema.yaml > generated.sql
          # Comparar estruturas...
```

---

## 🎓 Benefícios Demonstrados

1. **Versionamento** ✅
   - Todo histórico preservado
   - Fácil reverter mudanças

2. **Colaboração** ✅
   - Code review de schemas
   - Trabalho paralelo em branches

3. **Documentação** ✅
   - Schema é autodocumentado
   - Sempre atualizado

4. **Automação** ✅
   - CI/CD valida mudanças
   - Deploy automatizado

5. **Rastreabilidade** ✅
   - Sabe quem mudou o quê e quando
   - Contexto das decisões preservado

6. **Segurança** ✅
   - Mudanças controladas
   - Backup antes de aplicar
   - Rollback disponível

---

## 💡 Dicas Finais

### ✅ Boas Práticas

- Sempre criar backup antes de aplicar migrations
- Testar migrations em ambiente de staging primeiro
- Migrations devem ser idempotentes quando possível
- Nunca modificar migrations já aplicadas em produção
- Documentar WHY além de WHAT nas migrations
- Usar transações quando apropriado
- Manter schema.yaml sempre sincronizado

### ❌ O que NÃO fazer

- Não commitar credenciais no schema.yaml
- Não pular números de migrations
- Não modificar migrations já aplicadas
- Não fazer grandes mudanças sem backup
- Não aplicar migrations direto em produção sem testar

