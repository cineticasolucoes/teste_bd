# Database as Code - Exemplo E-commerce

Este é um exemplo prático de **Database as Code** usando YAML para definir o schema do banco de dados de forma versionável e legível.

## 📁 Estrutura do Projeto

```
exemplo-bd/
├── schema.yaml                      # Schema completo do banco de dados
├── migrations/                      # Migrações SQL versionadas
│   ├── 001_create_initial_schema.sql
│   └── 002_add_produto_slug.sql
├── seeds/                           # Dados de exemplo para desenvolvimento
│   └── dev-data.yaml
└── README.md                        # Este arquivo
```

## 📋 O que é Database as Code?

É a prática de **versionar o schema do banco de dados** em arquivos de texto (como YAML, JSON ou SQL) que podem ser:

- ✅ Versionados no Git
- ✅ Revisados em Pull Requests
- ✅ Revertidos quando necessário
- ✅ Documentados com comentários
- ✅ Compartilhados entre a equipe
- ✅ Usados para gerar SQL automaticamente

## 🎯 Arquivos Principais

### 1. `schema.yaml`

**Propósito:** Define o estado atual do banco de dados de forma declarativa.

**Conteúdo:**
- Metadados do banco
- Definição de todas as tabelas (entidades)
- Campos com tipos, constraints e descrições
- Índices
- Relacionamentos entre tabelas

**Vantagens:**
- Legível por humanos
- Fácil de entender a estrutura completa
- Pode ser usado para gerar SQL, diagramas, documentação
- Serve como fonte única da verdade

### 2. `migrations/`

**Propósito:** Scripts SQL que aplicam mudanças incrementais no banco.

**Convenção de nomenclatura:**
```
XXX_descricao_da_mudanca.sql
```

**Como funciona:**
1. Cada migration é executada **uma única vez**
2. Migrations são aplicadas em ordem numérica
3. Sistema rastreia quais migrations já foram aplicadas
4. Permite evoluir o banco sem perder dados

**Exemplo:**
- `001_create_initial_schema.sql` - Cria estrutura inicial
- `002_add_produto_slug.sql` - Adiciona campo slug aos produtos

### 3. `seeds/dev-data.yaml`

**Propósito:** Dados de exemplo para desenvolvimento/testes.

**Características:**
- Dados fictícios mas realistas
- Usado apenas em ambientes de dev/test
- **NUNCA** usado em produção
- Facilita testes manuais e automatizados

## 🚀 Como Usar

### Criando o Banco de Dados

#### Opção 1: A partir do YAML (futuro)
```bash
# Ferramenta que você vai criar:
mova-design generate-sql schema.yaml > create-database.sql
psql -U postgres -d seu_banco < create-database.sql
```

#### Opção 2: Executando Migrations
```bash
# Executar todas as migrations em ordem
psql -U postgres -d seu_banco < migrations/001_create_initial_schema.sql
psql -U postgres -d seu_banco < migrations/002_add_produto_slug.sql
```

### Populando com Dados de Exemplo

```bash
# Converter YAML para SQL (você implementará isso)
mova-design generate-seeds seeds/dev-data.yaml > insert-data.sql
psql -U postgres -d seu_banco < insert-data.sql
```

## 📊 Schema do E-commerce

O exemplo implementa um sistema básico de e-commerce com:

### Entidades

1. **Usuario** - Usuários do sistema
   - Autenticação (email/senha)
   - Dados pessoais (nome, CPF, data nascimento)

2. **Endereco** - Endereços de entrega
   - Múltiplos endereços por usuário
   - Endereço padrão marcado

3. **Categoria** - Categorias de produtos
   - Organização dos produtos

4. **Produto** - Produtos à venda
   - Preço, estoque, descrição
   - Vinculado a uma categoria
   - Slug para URLs amigáveis

5. **Pedido** - Pedidos dos usuários
   - Status do pedido
   - Valores (subtotal, desconto, frete, total)
   - Vinculado a usuário e endereço

6. **ItemPedido** - Itens de cada pedido
   - Produtos comprados
   - Quantidade e preço no momento da compra

### Relacionamentos

```
Usuario (1) ----< (N) Endereco
Usuario (1) ----< (N) Pedido
Categoria (1) ----< (N) Produto
Pedido (1) ----< (N) ItemPedido
Produto (1) ----< (N) ItemPedido
Pedido (N) >---- (1) Endereco
```

## 🔄 Workflow Típico

### Adicionando uma Nova Feature

1. **Modificar o `schema.yaml`**
   ```yaml
   # Adicionar novo campo
   Produto:
     fields:
       peso:
         type: decimal
         precision: 10
         scale: 3
         nullable: true
         description: Peso em quilogramas
   ```

2. **Criar Migration**
   ```sql
   -- migrations/003_add_produto_peso.sql
   ALTER TABLE produto 
   ADD COLUMN peso DECIMAL(10, 3);
   
   COMMENT ON COLUMN produto.peso IS 'Peso em quilogramas';
   ```

3. **Commitar no Git**
   ```bash
   git add schema.yaml migrations/003_add_produto_peso.sql
   git commit -m "feat: adiciona peso ao produto"
   git push
   ```

4. **Aplicar em Produção**
   ```bash
   psql -U postgres -d producao < migrations/003_add_produto_peso.sql
   ```

## ✨ Benefícios do Approach

### 1. Versionamento
- Histórico completo de mudanças no schema
- Pode fazer rollback se necessário
- Branches para experimentar mudanças

### 2. Colaboração
- Code review de mudanças no banco
- Comentários inline explicam decisões
- Toda equipe entende a estrutura

### 3. Automação
- CI/CD pode validar o schema
- Testes automatizados podem recriar o banco
- Deploy automático de migrations

### 4. Documentação
- O YAML é autodocumentado
- Fácil gerar diagramas ER automaticamente
- Sempre atualizado (código é a documentação)

### 5. Portabilidade
- Fácil recriar banco em novo ambiente
- Desenvolvedores podem ter banco local idêntico
- Migrar entre diferentes SGBDs (com adaptações)

## 🛠️ Próximos Passos

Para tornar isso realmente útil, você precisaria criar ferramentas que:

1. **Leiam o YAML e gerem SQL**
   ```bash
   mova-design generate-sql schema.yaml --database postgres
   ```

2. **Comparem schemas e gerem migrations**
   ```bash
   mova-design diff old-schema.yaml new-schema.yaml > migration.sql
   ```

3. **Validem o schema**
   ```bash
   mova-design validate schema.yaml
   ```

4. **Gerem diagramas ER**
   ```bash
   mova-design generate-diagram schema.yaml > diagram.svg
   ```

5. **Sincronizem com banco existente**
   ```bash
   mova-design sync schema.yaml --connection postgresql://localhost/mydb
   ```

## 📚 Referências

- [Liquibase](https://www.liquibase.org/) - Ferramenta madura para database migrations
- [Flyway](https://flywaydb.org/) - Migrations simples e eficazes
- [Prisma](https://www.prisma.io/) - ORM moderno com schema declarativo
- [Atlas](https://atlasgo.io/) - Database schema as code moderno

## 🎓 Conclusão

Este exemplo demonstra como é possível **tratar o schema do banco de dados como código**, obtendo todos os benefícios de versionamento, colaboração e automação que já usamos no desenvolvimento de software.

A combinação de:
- **Schema declarativo (YAML)** - para entender o estado completo
- **Migrations incrementais (SQL)** - para evoluir com segurança
- **Seeds (YAML)** - para facilitar desenvolvimento

Cria um sistema robusto e profissional de gerenciamento de banco de dados.

