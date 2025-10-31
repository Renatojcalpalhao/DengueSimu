import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import json
import os

# Caminhos dos arquivos
csv_path = "../Data/csv/clima_santo_amaro.csv"
json_path = "../Data/dengue_data2.json"
output_dir = "../Data/graficos"

# Cria a pasta de saída, se não existir
os.makedirs(output_dir, exist_ok=True)

try:
    # ---- LEITURA DOS DADOS ----
    print("📥 Lendo dados climáticos e de dengue...")

    clima_df = pd.read_csv(csv_path)
    with open(json_path, "r", encoding="utf-8") as f:
        dengue_data = json.load(f)

    dengue_df = pd.DataFrame(dengue_data)

    # Converte data para o formato de data
    clima_df["data"] = pd.to_datetime(clima_df["data"])
    dengue_df["data"] = pd.to_datetime(dengue_df["data"])

    # ---- JUNÇÃO DOS DADOS ----
    merged_df = pd.merge(clima_df, dengue_df, on="data", how="inner")

    # ---- CÁLCULOS ESTATÍSTICOS ----
    print("📊 Calculando estatísticas e correlações...")
    resumo = {
        "Temperatura Média (°C)": clima_df["temperatura_media"].mean(),
        "Umidade Média (%)": clima_df["umidade"].mean(),
        "Chuva Média (mm)": clima_df["chuva"].mean(),
        "Casos Médios de Dengue": dengue_df["casos"].mean(),
        "Correlação Temp x Casos": merged_df["temperatura_media"].corr(merged_df["casos"]),
        "Correlação Chuva x Casos": merged_df["chuva"].corr(merged_df["casos"]),
        "Correlação Umidade x Casos": merged_df["umidade"].corr(merged_df["casos"]),
    }

    # Salva o resumo em arquivo de texto
    resumo_path = os.path.join(output_dir, "resumo_estatistico.txt")
    with open(resumo_path, "w", encoding="utf-8") as f:
        f.write("📈 RESUMO ESTATÍSTICO DOS RESULTADOS\n")
        f.write("=" * 45 + "\n")
        for k, v in resumo.items():
            f.write(f"{k}: {v:.2f}\n")
    print(f"✅ Resumo estatístico salvo em: {resumo_path}")

    # ---- GRÁFICOS ----
    print("📊 Gerando gráficos...")

    # 1. Casos de dengue ao longo do tempo
    plt.figure(figsize=(10, 5))
    plt.plot(dengue_df["data"], dengue_df["casos"], marker="o", color="red")
    plt.title("Casos de Dengue - Série Temporal")
    plt.xlabel("Data")
    plt.ylabel("Casos")
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, "casos_dengue.png"))
    plt.close()

    # 2. Temperatura vs Casos
    plt.figure(figsize=(6, 5))
    sns.scatterplot(x="temperatura_media", y="casos", data=merged_df, color="orange")
    plt.title("Correlação entre Temperatura e Casos de Dengue")
    plt.xlabel("Temperatura Média (°C)")
    plt.ylabel("Casos de Dengue")
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, "temperatura_vs_casos.png"))
    plt.close()

    # 3. Chuva vs Casos
    plt.figure(figsize=(6, 5))
    sns.scatterplot(x="chuva", y="casos", data=merged_df, color="blue")
    plt.title("Correlação entre Chuva e Casos de Dengue")
    plt.xlabel("Chuva (mm)")
    plt.ylabel("Casos de Dengue")
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, "chuva_vs_casos.png"))
    plt.close()

    # 4. Correlação completa (heatmap)
    plt.figure(figsize=(6, 4))
    sns.heatmap(merged_df[["temperatura_media", "umidade", "chuva", "casos"]].corr(), annot=True, cmap="coolwarm")
    plt.title("Mapa de Correlação entre Variáveis")
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, "mapa_correlacao.png"))
    plt.close()

    print("✅ Gráficos gerados e salvos em:", output_dir)

except Exception as e:
    print("❌ Erro ao gerar relatório:", e)
