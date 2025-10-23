# Sugestões de melhoria

- Padronizar caminhos (usar `Data/` ou `data/` em todo o projeto). O código e script foram ajustados para `Data/`.
- Consolidar espécies: manter todas em `models/dengueSim.gaml` ou extrair para `models/agents/*.gaml` e importar; remover duplicatas não utilizadas.
- Renomear `models/agents/mosquito.gam` para `.gaml` e alinhar nomes de espécies com o modelo principal (`mosquitos`, `humanos`).
- Integrar o shapefile `Data/shapefiles/shapes/…` como camada GIS no modelo, substituindo `envelope` por geometria real do distrito.
- Documentar no README como coletar clima (`scripts/clima_api.py`) e executar o experimento no GAMA.
- (Futuro) Estimar `r0_instantaneo` com base em novas infecções por janela de tempo.
