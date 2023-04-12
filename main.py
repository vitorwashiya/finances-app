import argparse

from dotenv import load_dotenv

parser = argparse.ArgumentParser()
parser.add_argument('--env-file', type=str, required=True)
args = parser.parse_args()
load_dotenv(dotenv_path=args.env_file)

from dependencies.environment_variables import TOKEN_API
from dependencies.general_functions import *

from telegram.ext import Application, CommandHandler


def main() -> None:
    application = Application.builder().token(TOKEN_API).build()
    application.add_handler(CommandHandler("add_category", add_category))
    application.add_handler(CommandHandler("add_subcategory", add_subcategory))
    application.add_handler(CommandHandler("help", help))
    application.add_handler(create_conversation_handler(CATEGORIAS_REGEX, SUB_CATEGORIAS_REGEX))
    application.run_polling()


if __name__ == "__main__":
    main()
