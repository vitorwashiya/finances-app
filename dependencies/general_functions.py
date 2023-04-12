global typed_number_var
global categoria_var
global sub_categoria_var

import logging
from typing import Union
from telegram import ReplyKeyboardMarkup, ReplyKeyboardRemove, Update
from telegram.ext import (
    ContextTypes,
    ConversationHandler,
    CommandHandler,
    MessageHandler,
    filters,
)

from dependencies.db_connector import DBConnector

connector = DBConnector()

placeholders = {
    "CATEGORIAS": "seleciona a categoria de custo",
    "SUB_CATEGORIAS": "Selecione a subcategoria do custo",
}

# Enable logging
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", level=logging.INFO
)
logger = logging.getLogger(__name__)

CATEGORIA_CUSTO, SUB_CATEGORIA_CUSTO = range(2)


def create_conversation_handler(CATEGORIAS_REGEX, SUB_CATEGORIAS_REGEX):
    conv_handler = ConversationHandler(
        entry_points=[MessageHandler(filters.ALL, start)],
        states={
            CATEGORIA_CUSTO: [MessageHandler(filters.Regex(CATEGORIAS_REGEX), categoria_custo)],
            SUB_CATEGORIA_CUSTO: [MessageHandler(filters.Regex(SUB_CATEGORIAS_REGEX), sub_categoria_custo)]
        },
        fallbacks=[CommandHandler("cancelar", cancel)],
    )
    return conv_handler


def transforma_lista_dict_em_regex(li_di: Union[list, dict]) -> str:
    li_final = []
    if isinstance(li_di, dict):
        for key in li_di.keys():
            for r in li_di[key]:
                li_final.extend(r)
    if isinstance(li_di, list):
        for r in li_di:
            li_final.extend(r)
    li_final = list(set(li_final))
    li_regex = "^(" + "|".join(li_final) + ")$"
    return li_regex


LISTA_CATEGORIAS = connector.get_list_categorias()
DICT_SUB_CATEGORIAS = connector.get_dict_sub_categorias()
CATEGORIAS_REGEX = transforma_lista_dict_em_regex(LISTA_CATEGORIAS)
SUB_CATEGORIAS_REGEX = transforma_lista_dict_em_regex(DICT_SUB_CATEGORIAS)


async def check_number(text):
    number = ''.join([i.replace(',', '.') for i in text if i.isdigit() or i in ('.', ',')])
    return number


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    global LISTA_CATEGORIAS
    global typed_number_var
    reply_keyboard = LISTA_CATEGORIAS
    typed_number_var = await check_number(update.message.text)
    if typed_number_var == '':
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
    global categoria_var
    global DICT_SUB_CATEGORIAS
    categoria_var = update.message.text
    user = update.message.from_user
    logger.info("Categoria de custo digitado por %s: %s", user.first_name, update.message.text)
    reply_keyboard = DICT_SUB_CATEGORIAS[update.message.text.title()]
    placeholder = placeholders["SUB_CATEGORIAS"]
    await update.message.reply_text(
        "Entendido! por favor selecione a subcategoria correspondente: Caso deseje cancelar a operação digite /cancelar",
        reply_markup=ReplyKeyboardMarkup(
            reply_keyboard, one_time_keyboard=True, input_field_placeholder=placeholder
        ),
    )
    return SUB_CATEGORIA_CUSTO


async def sub_categoria_custo(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    global typed_number_var
    global categoria_var
    global sub_categoria_var
    sub_categoria_var = update.message.text
    user = update.message.from_user
    logger.info("Sub categoria do custo digitado %s: %s", user.first_name, update.message.text)
    await connector.cadastra_custo(typed_number_var, categoria_var, sub_categoria_var, logger)
    typed_number_var = ''
    categoria_var = ''
    sub_categoria_var = ''
    await update.message.reply_text(
        "Maravilha o seu custo foi cadastrado com sucesso!"
    )
    return ConversationHandler.END


async def cancel(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    user = update.message.from_user
    logger.info("Usuario decidiu cancelar a operação.", user.first_name)
    await update.message.reply_text(
        "Operação cancelada.", reply_markup=ReplyKeyboardRemove()
    )
    return ConversationHandler.END


async def help(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Bem vindo ao seu gestor financeiro\n"
                                    "Você pode adicionar uma nova categoria usando /add_category {nome da nova categoria}\n"
                                    "Você pode adicionar uma nova subcategoria usando /add_subcategory {nome da categoria} | {nome da subcategoria}\n"
                                    "Ou pode adicionar um novo custo digitando um numero!")


async def add_category(update: Update, context: ContextTypes.DEFAULT_TYPE):
    nm_categoria = update.message.text.replace("/add_category ", "").title().strip()
    await connector.cadastra_categoria(nm_categoria)
    logger.info(f"Nova categoria inserida a base {nm_categoria}")
    await update.message.reply_text(f"Nova categoria inserida na base {nm_categoria}")

    global LISTA_CATEGORIAS, DICT_SUB_CATEGORIAS, CATEGORIAS_REGEX, SUB_CATEGORIAS_REGEX
    LISTA_CATEGORIAS = connector.get_list_categorias()
    DICT_SUB_CATEGORIAS = connector.get_dict_sub_categorias()
    CATEGORIAS_REGEX = transforma_lista_dict_em_regex(LISTA_CATEGORIAS)
    SUB_CATEGORIAS_REGEX = transforma_lista_dict_em_regex(DICT_SUB_CATEGORIAS)

    current_handlers = context.application.handlers[0]
    for handler in current_handlers:
        if isinstance(handler, ConversationHandler):
            context.application.remove_handler(handler)
    conv_handler = create_conversation_handler(CATEGORIAS_REGEX, SUB_CATEGORIAS_REGEX)
    context.application.add_handler(conv_handler)

    return LISTA_CATEGORIAS, DICT_SUB_CATEGORIAS, CATEGORIAS_REGEX, SUB_CATEGORIAS_REGEX


async def add_subcategory(update: Update, context: ContextTypes.DEFAULT_TYPE):
    texto = update.message.text.replace("/add_subcategory ", "").title().strip()
    nm_categoria = texto.split("|")[0].strip()
    nm_subcategoria = texto.split("|")[1].strip()
    result = await connector.cadastra_subcategoria(nm_categoria, nm_subcategoria, update)
    if result:
        await update.message.reply_text(f"Nova subcategoria {nm_subcategoria} inserida na base com "
                                        f"categoria {nm_categoria}")
    else:
        await update.message.reply_text(f"Não foi possivel encontrar a categoria digitada {nm_categoria}, "
                                        f"tente novamente.")

    global LISTA_CATEGORIAS, DICT_SUB_CATEGORIAS, CATEGORIAS_REGEX, SUB_CATEGORIAS_REGEX
    LISTA_CATEGORIAS = connector.get_list_categorias()
    DICT_SUB_CATEGORIAS = connector.get_dict_sub_categorias()
    CATEGORIAS_REGEX = transforma_lista_dict_em_regex(LISTA_CATEGORIAS)
    SUB_CATEGORIAS_REGEX = transforma_lista_dict_em_regex(DICT_SUB_CATEGORIAS)

    current_handlers = context.application.handlers[0]
    for handler in current_handlers:
        if isinstance(handler, ConversationHandler):
            context.application.remove_handler(handler)
    conv_handler = create_conversation_handler(CATEGORIAS_REGEX, SUB_CATEGORIAS_REGEX)
    context.application.add_handler(conv_handler)

    return LISTA_CATEGORIAS, DICT_SUB_CATEGORIAS, CATEGORIAS_REGEX, SUB_CATEGORIAS_REGEX
