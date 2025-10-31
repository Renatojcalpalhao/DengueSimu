import requests
import pandas as pd
import datetime
import os

OUTPUT_PATH = os.path.join("..", "Data", "csv", "clima_sao_paulo.csv")

def coletar_clima(cidade="Sao Paulo", dias=20):
    base_url = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude": -23.55,  # São Paulo
        "longitude": -46.63,
        "daily": "temperature_2m_max,temperature_2m_min,precipitation_sum",
        "timezone": "America/Sao_Paulo",
    }

    resposta = requests.get(base_url, params=params)
    dados = resposta.json()
    datas = dados["daily"]["time"]
    max_t = dados["daily"]["temperature_2m_max"]
    min_t = dados["daily"]["temperature_2m_min"]
    chuva = dados["daily"]["precipitation_sum"]

    df = pd.DataFrame({
        "dia": range(1, len(datas) + 1),
        "data": datas,
        "temp_max": max_t,
        "temp_min": min_t,
        "chuva_mm": chuva
    })

    df = df.head(dias)
    df.to_csv(OUTPUT_PATH, index=False)
    print(f"✅ Arquivo salvo em: {OUTPUT_PATH}")

if __name__ == "__main__":
    coletar_clima()
