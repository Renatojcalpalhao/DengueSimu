import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# === CAMINHOS ===
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "..", "Data", "csv")

DENGUE_PATH = os.path.join(DATA_DIR, "dengue_sao_paulo.csv")
AGUA_PATH   = os.path.join(DATA_DIR, "agua_parada_sao_paulo.csv")
CLIMA_PATH  = os.path.join(DATA_DIR, "clima_santo_amaro.csv")

OUTPUT_DIR = os.path.join(DATA_DIR, "..", "graficos")
os.makedirs(OUTPUT_DIR, exist_ok=True)

def _normaliza_colunas(df):
    df = df.copy()
    df.columns = [c.strip().lower() for c in df.columns]
    return df

def _coalesce(cols_dict):
    """Recebe dict {'nome_final': [lista_de_opcoes]} e devolve dict com a primeira coluna existente."""
    pick = {}
    for final_name, options in cols_dict.items():
        chosen = None
        for opt in options:
            if opt in cols_dict.get("_all_cols", []):  # não usado; manter compatibilidade se quiser
                pass
        pick[final_name] = None  # preenchido depois
    return pick  # não usado diretamente

def carregar_dados():
    print("📥 Lendo arquivos CSV...")

    # --- Lê e normaliza
    df_dengue = _normaliza_colunas(pd.read_csv(DENGUE_PATH))
    df_agua   = _normaliza_colunas(pd.read_csv(AGUA_PATH))
    df_clima  = _normaliza_colunas(pd.read_csv(CLIMA_PATH))

    # --- Garante colunas essenciais / formatações
    # Dengue: vamos manter só 'dia' e 'casos'
    if "dia" not in df_dengue.columns:
        raise ValueError("Arquivo dengue_sao_paulo.csv precisa ter coluna 'dia'.")
    if "casos" not in df_dengue.columns:
        # tenta achar uma alternativa
        alt = [c for c in df_dengue.columns if "caso" in c]
        if not alt:
            raise ValueError("Arquivo dengue_sao_paulo.csv precisa ter coluna 'casos'.")
        df_dengue = df_dengue.rename(columns={alt[0]: "casos"})
    df_dengue = df_dengue[["dia", "casos"]].copy()
    df_dengue["dia"] = df_dengue["dia"].astype(int)

    # Água: garantir 'dia' e alguma coluna que represente água parada
    if "dia" not in df_agua.columns:
        raise ValueError("Arquivo agua_parada_sao_paulo.csv precisa ter coluna 'dia'.")
    df_agua["dia"] = df_agua["dia"].astype(int)

    # Detecta coluna de água parada (prioridade)
    agua_candidates = [c for c in df_agua.columns if "agua_parada" in c or "alag" in c]
    if not agua_candidates:
        # se não houver, mas tiver 'chuva' apenas, seguimos sem água_parada (o gráfico de água vai falhar)
        # criamos uma série nula para não quebrar os merges/plots (melhor feedback no gráfico)
        df_agua["agua_parada"] = 0
    else:
        # Padroniza para 'agua_parada'
        if "agua_parada" not in df_agua.columns:
            df_agua = df_agua.rename(columns={agua_candidates[0]: "agua_parada"})

    # Se houver uma coluna de chuva no arquivo de água, renomeia para não conflitar
    if "chuva" in df_agua.columns:
        df_agua = df_agua.rename(columns={"chuva": "chuva_agua_parada"})

    # Clima: criar 'dia' sequencial se não existir
    if "dia" not in df_clima.columns:
        df_clima = df_clima.copy()
        df_clima["dia"] = range(1, len(df_clima) + 1)

    # Padroniza nomes climáticos esperados
    # tenta achar temperatura média
    if "temperatura_media" not in df_clima.columns:
        alt_temp = [c for c in df_clima.columns if "temp" in c and "media" in c]
        if alt_temp:
            df_clima = df_clima.rename(columns={alt_temp[0]: "temperatura_media"})
    # tenta achar chuva
    if "chuva" not in df_clima.columns:
        alt_rain = [c for c in df_clima.columns if "chuva" in c or "precip" in c]
        if alt_rain:
            df_clima = df_clima.rename(columns={alt_rain[0]: "chuva"})

    # --- FUSÕES
    df = pd.merge(df_dengue, df_agua, on="dia", how="left")
    df = pd.merge(df, df_clima, on="dia", how="left")

    # --- Resolve duplicatas/ausências de colunas finais
    # água_parada: preferimos 'agua_parada'; se não existir, tenta as variantes comuns
    if "agua_parada" not in df.columns:
        for cand in ["agua_parada_x", "agua_parada_y"]:
            if cand in df.columns:
                df["agua_parada"] = df[cand]
                break
    # se ainda não existir, cria com zeros
    if "agua_parada" not in df.columns:
        df["agua_parada"] = 0

    # chuva: preferimos do clima
    if "chuva" not in df.columns:
        # se não houver no clima, tenta vir do arquivo de água
        for cand in ["chuva_x", "chuva_y", "chuva_agua_parada"]:
            if cand in df.columns:
                df["chuva"] = df[cand]
                break
    # se ainda não existir, cria com zeros
    if "chuva" not in df.columns:
        df["chuva"] = 0

    print(f"✅ Dados combinados: {len(df)} registros")
    print(df.head(10))
    return df

def gerar_graficos(df):
    print("📊 Gerando gráficos...")

    # 1) Casos x Água Parada
    plt.figure(figsize=(8,5))
    plt.plot(df["dia"], df["casos"], marker="o", color="red", label="Casos de Dengue")
    plt.plot(df["dia"], df["agua_parada"], marker="s", color="blue", label="Água Parada")
    plt.title("Casos de Dengue vs Ocorrências de Água Parada")
    plt.xlabel("Dia")
    plt.ylabel("Quantidade")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, "dengue_vs_agua.png"))
    plt.close()

    # 2) Temperatura e Chuva
    if "temperatura_media" in df.columns:
        plt.figure(figsize=(8,5))
        plt.plot(df["dia"], df["temperatura_media"], color="orange", label="Temperatura Média (°C)")
        plt.plot(df["dia"], df["chuva"], color="cyan", label="Chuva (mm)")
        plt.title("Temperatura e Chuva - Série Temporal")
        plt.xlabel("Dia")
        plt.legend()
        plt.grid(True)
        plt.tight_layout()
        plt.savefig(os.path.join(OUTPUT_DIR, "clima_series.png"))
        plt.close()

    # 3) Correlação
    corr_cols = [c for c in ["casos", "agua_parada", "chuva", "temperatura_media"] if c in df.columns]
    if len(corr_cols) >= 2:
        plt.figure(figsize=(6,5))
        sns.heatmap(df[corr_cols].corr(), annot=True, cmap="coolwarm")
        plt.title("Mapa de Correlação entre Variáveis")
        plt.tight_layout()
        plt.savefig(os.path.join(OUTPUT_DIR, "mapa_correlacao.png"))
        plt.close()

    print(f"✅ Gráficos salvos em: {OUTPUT_DIR}")

def processar():
    try:
        df = carregar_dados()
        gerar_graficos(df)
        print("🏁 Processamento concluído com sucesso!")
    except Exception as e:
        print(f"❌ Erro ao processar dados: {e}")

if __name__ == "__main__":
    processar()
