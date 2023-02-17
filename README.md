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

### Rode o arquivo main.py e o seu bot estará ativo.

```commandline
python main.py --env-file "path/to/envfile.env"
```


