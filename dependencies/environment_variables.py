import os

TOKEN_API = os.getenv("TOKEN_API")
DB_PATH = os.getenv("DB_PATH")

placeholders = {
    "CATEGORIAS": "seleciona a categoria de custo",
    "SUB_CATEGORIAS": "Selecione a subcategoria do custo",
}

CATEGORIA_CUSTO, SUB_CATEGORIA_CUSTO = range(2)