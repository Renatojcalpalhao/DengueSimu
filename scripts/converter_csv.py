import pandas as pd
import os

# Caminhos dos arquivos
input_path = r'C:\Users\renat\Gama_Workspace\DengueSimu\Data\csv\dengue_sao_paulo.csv'
output_path = r'C:\Users\renat\Gama_Workspace\DengueSimu\Data\csv\dengue_sao_paulo_utf8.csv'

# Verifica se o arquivo existe
if not os.path.exists(input_path):
    print(f"❌ Arquivo não encontrado: {input_path}")
else:
    try:
        # Lê o arquivo original (Excel geralmente usa ';' como separador)
        df = pd.read_csv(input_path, delimiter=';')

        # Salva novamente com vírgulas e codificação UTF-8
        df.to_csv(output_path, index=False, encoding='utf-8')

        print("✅ Arquivo convertido com sucesso!")
        print("Novo arquivo salvo em:", output_path)

    except Exception as e:
        print("⚠️ Erro durante a conversão:", e)
