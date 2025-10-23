import os
import json
import pandas as pd
import matplotlib.pyplot as plt

# Caminho do arquivo de dados
DATA_PATH = os.path.join("..", "data", "dengue_data.json")

def criar_dados_exemplo():
    """Cria um arquivo JSON de exemplo se não existir."""
    exemplo = [
        {"dia": 1, "casos": 10, "agua_parada": 5, "chuva": 20},
        {"dia": 2, "casos": 15, "agua_parada": 8, "chuva": 10},
        {"dia": 3, "casos": 25, "agua_parada": 10, "chuva": 30},
        {"dia": 4, "casos": 30, "agua_parada": 12, "chuva": 25},
        {"dia": 5, "casos": 28, "agua_parada": 9, "chuva": 5}
    ]
    with open(DATA_PATH, "w", encoding="utf-8") as f:
        json.dump(exemplo, f, indent=4, ensure_ascii=False)
    print("✅ Arquivo de exemplo 'dengue_data.json' criado em 'data/'.")

def carregar_dados():
    """Carrega os dados JSON em um DataFrame do Pandas."""
    if not os.path.exists(DATA_PATH):
        print("⚠️ Arquivo de dados não encontrado. Criando exemplo...")
        criar_dados_exemplo()
    
    with open(DATA_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    return pd.DataFrame(data)

def gerar_graficos(df):
    """Gera gráficos simples com base nos dados."""
    plt.figure(figsize=(8,5))
    plt.plot(df["dia"], df["casos"], marker="o", label="Casos de Dengue")
    plt.plot(df["dia"], df["agua_parada"], marker="s", label="Locais com Água Parada")
    plt.xlabel("Dia da Simulação")
    plt.ylabel("Quantidade")
    plt.title("Simulação de Casos de Dengue vs Água Parada")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.savefig("../data/grafico_dengue.png")
    plt.show()
    print("📊 Gráfico salvo em 'data/grafico_dengue.png'.")

def processar():
    """Executa o processamento completo."""
    try:
        df = carregar_dados()
        print("✅ Dados carregados com sucesso!")
        print(df.head())
        gerar_graficos(df)
        print("✅ Processamento concluído!")
    except Exception as e:
        print(f"❌ Erro ao processar dados: {e}")

if __name__ == "__main__":
    processar()
