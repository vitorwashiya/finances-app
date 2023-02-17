global typed_number
global categoria
global sub_categoria
import time
import sqlite3

from dependencies.environment_variables import LISTA_CATEGORIAS, LISTA_ESSENCIAL, LISTA_LAZER, DB_PATH
from telegram import ReplyKeyboardMarkup, ReplyKeyboardRemove, Update
import logging
from telegram.ext import (
    ContextTypes,
    ConversationHandler
)

placeholders = {
    "CATEGORIAS": ", ".join(LISTA_CATEGORIAS[0]) + "?",
    "ESSENCIAL": ", ".join(LISTA_ESSENCIAL[0]) + "?",
    "LAZER": ", ".join(LISTA_LAZER[0]) + "?"
}

listas = {
    "CATEGORIAS": LISTA_CATEGORIAS,
    "ESSENCIAL": LISTA_ESSENCIAL,
    "LAZER": LISTA_LAZER
}

# Enable logging
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", level=logging.INFO
)
logger = logging.getLogger(__name__)

CATEGORIA_CUSTO, SUB_CATEGORIA_CUSTO = range(2)


async def check_number(text):
    number = ''.join([i.replace(',', '.') for i in text if i.isdigit() or i in ('.', ',')])
    return number


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    global typed_number
    reply_keyboard = LISTA_CATEGORIAS
    typed_number = await check_number(update.message.text)
    if typed_number == '':
        await update.message.reply_text("O valor digitado é invalido, por favor digite novamente.")
    else:
        await update.message.reply_text(
            "Por favor selecione a categoria deste custo: Caso deseje cancelar a operação digite /cancelar",
            reply_markup=ReplyKeyboardMarkup(
                reply_keyboard, one_time_keyboard=True, input_field_placeholder=placeholders["CATEGORIAS"]
            ),
        )
        return CATEGORIA_CUSTO


async def categoria_custo(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    global categoria
    categoria = update.message.text
    user = update.message.from_user
    logger.info("Categoria de custo digitado por %s: %s", user.first_name, update.message.text)
    if update.message.text in LISTA_CATEGORIAS[0]:
        reply_keyboard = listas[update.message.text.upper()]
        placeholder = placeholders[update.message.text.upper()]
    else:
        reply_keyboard = listas[LISTA_CATEGORIAS[0][0].upper()]
        placeholder = placeholders[LISTA_CATEGORIAS[0][0].upper()]
    await update.message.reply_text(
        "Entendido! por favor selecione a subcategoria correspondente: Caso deseje cancelar a operação digite /cancelar",
        reply_markup=ReplyKeyboardMarkup(
            reply_keyboard, one_time_keyboard=True, input_field_placeholder=placeholder
        ),
    )
    return SUB_CATEGORIA_CUSTO


async def sub_categoria_custo(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    global sub_categoria
    sub_categoria = update.message.text
    user = update.message.from_user
    logger.info("Sub categoria do custo digitado %s: %s", user.first_name, update.message.text)
    await cadastra_custo()
    await update.message.reply_text(
        "Maravilha o seu custo foi cadastrado com sucesso!"
    )
    return ConversationHandler.END


async def cadastra_custo():
    global typed_number
    global categoria
    global sub_categoria
    data_transacao = time.strftime("%Y-%m-%d")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO financial_transactions (data_transacao, categoria, sub_categoria, valor) VALUES (?, ?, ?, ?)",
        (data_transacao, categoria, sub_categoria, typed_number))
    conn.commit()
    conn.close()
    logger.info("Valores digitados %s, %s, %s", typed_number, categoria, sub_categoria)
    typed_number=''
    categoria=''
    sub_categoria=''


async def cancel(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    user = update.message.from_user
    logger.info("Usuario decidiu cancelar a operação.", user.first_name)
    await update.message.reply_text(
        "Operação cancelada.", reply_markup=ReplyKeyboardRemove()
    )
    return ConversationHandler.END
