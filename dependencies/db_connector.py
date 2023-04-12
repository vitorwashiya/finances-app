import sqlite3
import time

from dependencies.environment_variables import DB_PATH


class DBConnector:

    @staticmethod
    def get_list_categorias() -> list:
        connector = sqlite3.connect(DB_PATH)
        cursor = connector.cursor()
        query = "SELECT nm_categoria FROM categorias WHERE nm_categoria_pai IS NULL"
        result = cursor.execute(query)
        result = [r[0] for r in result.fetchall()]
        result = [result[i:i + 3] for i in range(0, len(result), 3)]
        cursor.close()
        return result

    @staticmethod
    def get_dict_sub_categorias() -> dict:
        connector = sqlite3.connect(DB_PATH)
        cursor = connector.cursor()
        query = "SELECT nm_categoria, nm_categoria_pai FROM categorias WHERE nm_categoria_pai IS NOT NULL"
        result = cursor.execute(query)
        result = [r for r in result.fetchall()]
        list_categorias = list(set([r[1] for r in result]))
        dict_result = dict()
        for cat in list_categorias:
            list_sub_categorias = [r[0] for r in result if r[1] == cat]
            dict_result[cat] = [list_sub_categorias[i: i + 3] for i in range(0, len(list_sub_categorias), 3)]
        cursor.close()
        return dict_result
    @staticmethod
    async def cadastra_custo(typed_number, categoria, sub_categoria, logger) -> None:
        connector = sqlite3.connect(DB_PATH)
        data_transacao = time.strftime("%Y-%m-%d")
        cursor = connector.cursor()
        cursor.execute(
            "INSERT INTO financial_transactions (data_transacao, categoria, sub_categoria, valor) VALUES (?, ?, ?, ?)",
            (data_transacao, categoria, sub_categoria, typed_number))
        connector.commit()
        logger.info(f"valores digitados: {typed_number}, {categoria}, {sub_categoria}")
        cursor.close()

    @staticmethod
    async def cadastra_categoria(nm_categoria):
        connector = sqlite3.connect(DB_PATH)
        cursor = connector.cursor()
        query = f"""
            INSERT INTO categorias
            (nm_categoria, id_categoria_pai, nm_categoria_pai)
            VALUES('{nm_categoria}', null, null);
        """
        cursor.execute(query)
        connector.commit()
        cursor.close()

    @staticmethod
    async def cadastra_subcategoria(nm_categoria, nm_sub_categoria, update):
        connector = sqlite3.connect(DB_PATH)
        cursor = connector.cursor()
        query_pai = f"SELECT id FROM categorias WHERE nm_categoria = '{nm_categoria}'"
        result = cursor.execute(query_pai)
        result = [r for r in result.fetchall()]
        if len(result) > 0:
            id_pai = result[0][0]
            query = f"""
                INSERT INTO categorias
                (nm_categoria, id_categoria_pai, nm_categoria_pai)
                VALUES('{nm_sub_categoria}', {id_pai}, '{nm_categoria}');
            """
            cursor.execute(query)
            connector.commit()
        cursor.close()
        return len(result) > 0
