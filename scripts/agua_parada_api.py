import os
import pandas as pd
import requests

# Caminhos
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(BASE_DIR, "..", "Data", "csv")
OUTPUT_FILE = os.path.join(DATA_PATH, "agua_parada_sao_paulo.csv")

# URL do dataset público do GeoSampa (alagamentos/água parada)
GEOSAMPA_URL = "https://dados.prefeitura.sp.gov.br/dataset/ccbc07f1-22ff-4c61-95f1-3622214054af/resource/2c3d8f5b-7822-4c47-81aa-2b9a8753f87a/download/alagamentos.csv"

def baixar_csv_geosampa():
    """Baixa o arquivo CSV real do GeoSampa e salva localmente."""
    try:
        print("🌎 Baixando dados reais de alagamentos/água parada (GeoSampa)...")
        os.makedirs(DATA_PATH, exist_ok=True)
        response = requests.get(GEOSAMPA_URL, timeout=30)
        response.raise_for_status()

        with open(OUTPUT_FILE, "wb") as f:
            f.write(response.content)

        print(f"✅ Arquivo salvo em: {OUTPUT_FILE}")
        return True
    except Exception as e:
        print(f"❌ Erro ao baixar dados reais: {e}")
        return False


def carregar_e_tratar_dados():
    """Carrega o CSV e trata os dados principais."""
    if not os.path.exists(OUTPUT_FILE):
        sucesso = baixar_csv_geosampa()
        if not sucesso:
            print("⚠️ Criando dados simulados de fallback...")
            dados_simulados = {
                "dia": [1, 2, 3, 4, 5],
                "agua_parada": [5, 8, 10, 12, 9],
                "chuva": [20, 10, 30, 25, 5]
            }
            df = pd.DataFrame(dados_simulados)
            df.to_csv(OUTPUT_FILE, index=False, encoding="utf-8")
            print(f"✅ CSV simulado criado em {OUTPUT_FILE}")
            return df

    print("📊 Carregando dados de alagamentos...")
    df = pd.read_csv(OUTPUT_FILE, encoding="latin1")
    print(f"✅ Dados carregados! {len(df)} registros encontrados.")
    print(df.head(5))
    return df


if __name__ == "__main__":
    carregar_e_tratar_dados()
