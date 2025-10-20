import requests
import pandas as pd
from datetime import datetime, timedelta
import os

# 📍 Coordenadas de Santo Amaro, São Paulo
LAT = -23.652
LON = -46.713

# 🗓️ Definir intervalo (últimos 7 dias até hoje)
end_date = datetime.now().date()
start_date = end_date - timedelta(days=7)

# 🌦️ API da Open-Meteo (sem necessidade de chave)
url = (
    f"https://api.open-meteo.com/v1/forecast?"
    f"latitude={LAT}&longitude={LON}"
    f"&start_date={start_date}&end_date={end_date}"
    f"&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,relative_humidity_2m_max"
    f"&timezone=America/Sao_Paulo"
)

print("🔄 Coletando dados do clima de Santo Amaro...")
response = requests.get(url)
data = response.json()

if "daily" not in data:
    print("❌ Erro ao buscar dados da API.")
    exit()

# 📊 Converter dados em DataFrame
df = pd.DataFrame({
    "data": data["daily"]["time"],
    "temperatura_max": data["daily"]["temperature_2m_max"],
    "temperatura_min": data["daily"]["temperature_2m_min"],
    "umidade": data["daily"]["relative_humidity_2m_max"],
    "chuva": data["daily"]["precipitation_sum"]
})

# 🧮 Calcular temperatura média
df["temperatura_media"] = df[["temperatura_max", "temperatura_min"]].mean(axis=1)
df = df[["data", "temperatura_media", "umidade", "chuva"]]

# 📁 Caminho para salvar o CSV
output_dir = os.path.join("..", "data", "csv")
os.makedirs(output_dir, exist_ok=True)
output_path = os.path.join(output_dir, "clima_santo_amaro.csv")

# 💾 Salvar arquivo CSV
df.to_csv(output_path, index=False, encoding="utf-8")
print(f"✅ Dados salvos em: {output_path}")
print(df)
