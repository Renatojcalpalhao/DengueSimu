// ============================================================
// MODELO DE SIMULAÇÃO DA DENGUE - SANTO AMARO/SP
// Arquivo: models/dengueSim.gaml (MODELO BASE)
// ============================================================

// ===== IMPORTS: arquivos de agentes e dados =====
import "agents/area_risco.gaml";
import "agents/human.gaml";    // CORRIGIDO: O nome do arquivo é 'human.gaml'
import "agents/mosquito.gaml"; // O nome do arquivo é 'mosquito.gaml'
import "includes/dados.gaml";

// ================= GLOBAL =================
global {

    // -------------------------
    // 🔹 Arquivos externos (CSV gerados pelos scripts Python)
    // -------------------------
    file clima_csv <- file("../Data/csv/clima_santo_amaro.csv");
    file dengue_csv <- file("../Data/csv/dengue_sao_paulo.csv");
    file agua_parada_csv <- file("../Data/csv/agua_parada_sao_paulo.csv");

    // tabelas (lidas uma vez e consultadas durante a simulação)
    table clima_dados <- read_csv(clima_csv);          
    table dengue_dados <- exists(dengue_csv) ? read_csv(dengue_csv) : table[];
    table agua_parada_dados <- exists(agua_parada_csv) ? read_csv(agua_parada_csv) : table[];

    // -------------------------
    // 🔹 Variáveis de clima (serão atualizadas ciclicamente)
    // -------------------------
    float temperatura_externa <- if (length(clima_dados) > 0) float(clima_dados at 0 get "temperatura_media") else 26.8;
    float precipitacao <- if (length(clima_dados) > 0) float(clima_dados at 0 get "chuva") else 5.0;
    float umidade <- if (length(clima_dados) > 0) float(clima_dados at 0 get "umidade") else 75.0;

    // -------------------------
    // 🔹 Parâmetros epidemiológicos e ambientais
    // -------------------------
    float prob_transmissao_hum_mos <- 0.35;
    float prob_transmissao_mos_hum <- 0.45;
    int tempo_incubacao_mosquito <- 4; // dias

    // parâmetros que podem ser ajustados pelos experimentos
    float base_taxa_reproducao_mosquito <- 0.08; 
    float bonus_alagamento_reproducao <- 0.10;   

    // -------------------------
    // 🔹 Geografia Santo Amaro (envelope de teste)
    // -------------------------
    geometry santo_amaro_boundary <- envelope({-46.720, -23.660, -46.680, -23.620});
    point centro_santo_amaro <- {-46.700, -23.640};

    // -------------------------
    // 🔹 Métricas (monitoramento)
    // -------------------------
    int total_infectados_h <- 0;
    int total_recuperados <- 0;
    float r0_instantaneo <- 0.0;
    int ciclo_dia <- 0;

    // coleções de suporte
    list<point> criadouros_potenciais <- [];
    list<string> bairros_vizinhos <- ["Socorro", "Jardim São Luís", "Campo Belo", "Jurubatuba"];

    // -------------------------
    // 🔹 Estado auxiliar: mapeamentos
    // -------------------------
    map<string, int> casos_por_distrito <- map[];
    map<string, bool> agua_parada_por_distrito <- map[];

    // -------------------------
    // 🔹 Reflexo: Atualizar clima em tempo real (diário)
    // -------------------------
    reflex atualizar_clima {
        if (length(clima_dados) = 0) { return; }
        
        int dia_index <- cycle mod length(clima_dados); 
        
        temperatura_externa <- float(clima_dados at dia_index get "temperatura_media");
        precipitacao <- float(clima_dados at dia_index get "chuva");
        umidade <- float(clima_dados at dia_index get "umidade");
        ciclo_dia <- ciclo_dia + 1;
        write "🌤️ [Clima] Dia: " + ciclo_dia
              + " | Temp: " + temperatura_externa + "°C"
              + " | Umid: " + umidade + "%"
              + " | Chuva: " + precipitacao + "mm";
    }

    // -------------------------
    // 🔹 Reflexo: Atualizar dados de dengue e água parada (diário)
    // -------------------------
    reflex atualizar_dados_ambiente {
        // limpar mapas
        casos_por_distrito <- map[];
        agua_parada_por_distrito <- map[];

        // carregar casos de dengue (se disponível)
        if (length(dengue_dados) > 0) {
            loop i from: 0 to: (length(dengue_dados) - 1) {
                string distrito <- (dengue_dados at i get "distrito") as string;
                int casos <- int(float(dengue_dados at i get "casos_confirmados"));
                if (distrito = nil or distrito = "") { continue; }
                if (casos_por_distrito contains_key distrito) {
                    casos_por_distrito[distrito] <- casos_por_distrito[distrito] + casos;
                } else {
                    casos_por_distrito[distrito] <- casos;
                }
            }
            write "📊 Dados dengue carregados - distritos: " + size(casos_por_distrito);
        } else {
            write "⚠️ Arquivo de dengue não encontrado ou vazio.";
        }

        // carregar ocorrências de alagamento/água parada (se disponível)
        if (length(agua_parada_dados) > 0) {
            string coluna_distrito <- "";
            if (exists(agua_parada_dados at 0 get "REGIÃO ADMINISTRATIVA")) { coluna_distrito <- "REGIÃO ADMINISTRATIVA"; }
            else if (exists(agua_parada_dados at 0 get "REGIAO_ADMINISTRATIVA")) { coluna_distrito <- "REGIAO_ADMINISTRATIVA"; }
            else if (exists(agua_parada_dados at 0 get "REGIAO")) { coluna_distrito <- "REGIAO"; }
            else if (exists(agua_parada_dados at 0 get "REGIÃO")) { coluna_distrito <- "REGIÃO"; }
            else if (exists(agua_parada_dados at 0 get "MUNICÍPIO")) { coluna_distrito <- "MUNICÍPIO"; }

            loop i from: 0 to: (length(agua_parada_dados) - 1) {
                string distrito <- "";
                if (coluna_distrito != "") {
                    distrito <- (agua_parada_dados at i get coluna_distrito) as string;
                }
                if (distrito = nil or distrito = "") { continue; }
                agua_parada_por_distrito[distrito] <- true;
            }
            write "💧 Dados água parada/alagamentos carregados - distritos marcados: " + size(agua_parada_por_distrito);
        } else {
            write "⚠️ Arquivo de água parada não encontrado ou vazio.";
        }
    }
    
    // -------------------------
    // 🔹 NOVO REFLEXO: Exportar Resultados (diário para CSV)
    // -------------------------
    reflex exportar_metricas {
        // Ação chamada pela 'action daily_update' no arquivo de experimento
        
        list<map> data_export <- [
            map: [
                "dia": ciclo_dia,
                "temperatura_c": temperatura_externa,
                "chuva_mm": precipitacao,
                "umidade_perc": umidade,
                "infectados_humanos": total_infectados_h,
                "recuperados_humanos": total_recuperados,
                "mosquitos_infectivos": count(mosquitos where (infectivo)), 
                "r0_inst": r0_instantaneo
            ]
        ];
        
        string nome_arquivo <- "resultados/metricas_diarias_" + ciclo_dia + ".csv";
        
        write data_export as_csv: nome_arquivo;
        write "💾 Resultados do Dia " + ciclo_dia + " exportados para " + nome_arquivo;
    }
}

// ================= INIT =================
init {
    write "🔄 Iniciando simulação em Santo Amaro, Zona Sul de SP...";

    // 1) Criar Áreas de Risco
    create area_risco with: [
        new area_risco(nome: "Centro Santo Amaro", geometria: circle(800) at: centro_santo_amaro, nivel_risco: 4),
        new area_risco(nome: "Margens Pinheiros", geometria: circle(600) at: {-46.710, -23.635}, nivel_risco: 5),
        new area_risco(nome: "Jardim Santo Amaro", geometria: circle(700) at: {-46.695, -23.645}, nivel_risco: 3),
        new area_risco(nome: "Vila Socorro", geometria: circle(500) at: {-46.690, -23.655}, nivel_risco: 4)
    ];

    // 2) Criadouros potenciais aleatórios
    loop i from: 1 to: 20 {
        point c <- any_location_in(santo_amaro_boundary);
        area_risco a <- one_of(area_risco where (each.nivel_risco >= 4));
        if (a != nil) { c <- any_location_in(a.geometria); }
        criadouros_potenciais <- criadouros_potenciais + [c];
    }

    // 3) Inicializar mapas com dados externos
    do call (global.atualizar_dados_ambiente);

    // Aplicar casos carregados
    if (size(casos_por_distrito) > 0) {
        ask area_risco {
            if (global.casos_por_distrito contains_key each.nome) {
                each.casos_reportados <- global.casos_por_distrito[each.nome];
            }
        }
    }

    write "🎯 Modelo Base Carregado. Populações e Seed serão configurados pelo Experimento.";
}