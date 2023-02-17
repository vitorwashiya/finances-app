import argparse
from dotenv import load_dotenv

parser = argparse.ArgumentParser()
parser.add_argument('--env-file', type=str, required=True)
args = parser.parse_args()
load_dotenv(dotenv_path=args.env_file)

from dependencies.environment_variables import TOKEN_API, LISTA_CATEGORIAS, LISTA_ESSENCIAL, LISTA_LAZER
from dependencies.general_functions import *

cat_list = []
for listas in LISTA_CATEGORIAS:
    cat_list.extend(listas)
cat_list = list(set(cat_list))
CATEGORIAS_REGEX = "^(" + "|".join(cat_list) + ")$"

sub_cat_list = []
for listas1 in LISTA_LAZER:
    sub_cat_list.extend(listas)
for listas2 in LISTA_ESSENCIAL:
    sub_cat_list.extend(listas2)
sub_cat_list = list(set(sub_cat_list))
SUB_CATEGORIAS_REGEX = "^(" + "|".join(sub_cat_list) + ")$"

from telegram import __version__ as TG_VER

try:
    from telegram import __version_info__
except ImportError:
    __version_info__ = (0, 0, 0, 0, 0)  # type: ignore[assignment]

if __version_info__ < (20, 0, 0, "alpha", 5):
    raise RuntimeError(
        f"This example is not compatible with your current PTB version {TG_VER}. To view the "
        f"{TG_VER} version of this example, "
        f"visit https://docs.python-telegram-bot.org/en/v{TG_VER}/examples.html"
    )

from telegram.ext import (
    Application,
    CommandHandler,
    ConversationHandler,
    MessageHandler,
    filters,
)


def main() -> None:
    application = Application.builder().token(TOKEN_API).build()

    conv_handler = ConversationHandler(
        entry_points=[MessageHandler(filters.ALL, start)],
        states={
            CATEGORIA_CUSTO: [MessageHandler(filters.Regex(CATEGORIAS_REGEX), categoria_custo)],
            SUB_CATEGORIA_CUSTO: [MessageHandler(filters.Regex(SUB_CATEGORIAS_REGEX), sub_categoria_custo)]
        },
        fallbacks=[CommandHandler("cancelar", cancel)],
    )
    application.add_handler(conv_handler)

    application.run_polling()


if __name__ == "__main__":
    main()
