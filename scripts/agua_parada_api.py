import requests
import pandas as pd
from datetime import datetime

# URL de exemplo (iremos substituir depois por uma API real)
url = "https://dados.prefeitura.sp.gov.br/api/3/action/datastore_search?resource_id=EXEMPLO"

def obter_dados_agua_parada():
    print("🔍 Consultando dados de alagamentos/água parada...")
    response = requests.get(url)

    if response.status_code == 200:
        dados = response.json()
        registros = dados.get("result", {}).get("records", [])

        if registros:
            df = pd.DataFrame(registros)
            df["data_coleta"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            df.to_csv("agua_parada_sp.csv", index=False, encoding="utf-8")
            print("💾 Dados salvos em agua_parada_sp.csv")
        else:
            print("⚠️ Nenhum dado encontrado.")
    else:
        print(f"❌ Erro ao acessar API: {response.status_code}")

if __name__ == "__main__":
    obter_dados_agua_parada()
