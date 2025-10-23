## Objetivo

Este PR aplica ajustes mínimos para estabilizar o modelo no GAMA e prepara a estrutura do repositório para o TCC.

## Mudanças principais
- Correção do caminho do CSV de clima (`Data/csv/clima_santo_amaro.csv`).
- Remoção de chave extra no bloco `global` do modelo GAML.
- Adição do reflexo `global.atualizar_metricas` e ajuste do experimento para chamá-lo junto de `global.atualizar_clima`.
- Criação da pasta `tcc/` com `.gitkeep` para receber os arquivos do TCC.

## Instruções ao aluno
- Escrever e versionar o trabalho do TCC em LaTeX dentro da pasta `tcc/`.
  - Ex.: `tcc/main.tex`, `tcc/referencias.bib`, `tcc/figuras/…`.
  - Incluir um `README.md` rápido em `tcc/` com instruções de compilação (pdflatex/latexmk).

## Próximas melhorias sugeridas
- Padronizar nomes/estruturas de espécies (consolidar `models/agents` ou remover duplicatas não usadas).
- Integrar shapefile real de Santo Amaro no ambiente do modelo (substituir `envelope` por geometria GIS).
- Documentar passos de execução no GAMA e coleta de dados climáticos.
- (Opcional) Adicionar um script simples para validação de consistência de paths/csv.

## Checklist
- [ ] Adicionar estrutura LaTeX do TCC em `tcc/`.
- [ ] Conferir execução do experimento `santo_amaro_simulacao` no GAMA.
- [ ] Validar atualização do CSV via `scripts/clima_api.py`.

