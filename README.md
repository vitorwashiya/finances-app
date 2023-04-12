# Finance App

## Phase 1 - Telegram
Inicialmente iremos criar o app para realizar a comunicação entre o usuário e o telegram

### Pegar Telegram Token API
  * Acesse o telegram.
  * Vá para @BotFather.
  * Digite /start para ouvir o menu de opções.
  * Digite /newbot e siga os passos para a criação do Bot.
  * Após criação do Bot, digite /setinline para ativar a opção de inline.

### Adicione variáveis de ambiente
  * Adicione o Token obtido na variável de ambiente TOKEN_API
  * Crie um banco de dados SQLite ou utilize o fornecido e adicione a variavel de ambiente DB_PATH

### criação da database

CREATE TABLE financial_transactions (
    data_transacao DATE,
    categoria TEXT,
    sub_categoria TEXT,
    valor FLOAT
);

CREATE TABLE categorias (
	id INTEGER primary key autoincrement not null,
    nm_categoria TEXT,
    id_categoria_pai bigint,
    nm_categoria_pai TEXT
);

-- OPTIONAL VIEW
CREATE VIEW vw_relatorio_transacoes AS 
	SELECT 
		strftime('%Y-%m', data_transacao) as ano_mes
		, categoria
		, sub_categoria
		, SUM(valor) as total
	FROM 
		financial_transactions
	GROUP BY 
		ano_mes, categoria, sub_categoria
	ORDER BY 
		ano_mes, categoria, sub_categoria;



### Rode o arquivo main.py e o seu bot estará ativo.

```commandline
python main.py --env-file "path/to/envfile.env"
```

### Features
O robo possui as seguintes features
* Cadastrar um novo custo ao banco de dados
* adicionar uma nova categoria
* adicionar uma nova subcategoria 

