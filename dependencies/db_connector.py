import os
import sqlite3

from dependencies.environment_variables import DB_PATH


class DBConnector:
    def __init__(self):
        self.connector = sqlite3.connect(DB_PATH)

    def get_list_categorias(self) -> list:
        cursor = self.connector.cursor()
        query = "SELECT nm_categoria FROM categorias WHERE nm_categoria_pai IS NULL"
        result = cursor.execute(query)
        result = [r[0] for r in result.fetchall()]
        result = [result[i:i + 3] for i in range(0, len(result), 3)]
        self.connector.commit()
        cursor.close()
        return result

    def get_dict_sub_categorias(self) -> dict:
        cursor = self.connector.cursor()
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
