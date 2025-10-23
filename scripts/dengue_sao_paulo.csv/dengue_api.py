# scripts/dengue_api.py
import requests
import pandas as pd
from datetime import datetime
import os

# Caminho do arquivo de saída
OUTPUT_DIR = os.path.join("..", "Data", "csv")
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "dengue_sao_paulo.csv")

# URL base (exemplo de fonte real — depois ajustamos)
API_URL = "https://dados.prefeitura.sp.gov.br/api/3/action/datastore_search?resource_id=ID_DO_DATASET"

def coletar_dados_dengue():
    print("🔄 Coletando dados de dengue em São Paulo...")

    try:
        # Exemplo: se a API não estiver disponível, cria dados simulados
        # (você pode trocar depois pelo requests.get(API_URL).json())
        data_atual = datetime.now().strftime("%Y-%m-%d")
        distritos = ["Santo Amaro", "Moema", "Campo Belo", "Socorro"]
        casos = [42, 31, 27, 15]

        df = pd.DataFrame({
            "data": [data_atual] * len(distritos),
            "distrito": distritos,
            "casos_confirmados": casos
        })

        os.makedirs(OUTPUT_DIR, exist_ok=True)
        df.to_csv(OUTPUT_FILE, index=False, encoding="utf-8")

        print(f"✅ Dados de dengue salvos em: {OUTPUT_FILE}")
        print(df)

    except Exception as e:
        print("❌ Erro ao coletar dados:", e)

if __name__ == "__main__":
    coletar_dados_dengue()
