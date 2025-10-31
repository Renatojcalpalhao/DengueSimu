model DengueSimu

// ============================================================
// MODELO DE SIMULAÇÃO DA DENGUE - SANTO AMARO/SP
// Integração com APIs em Python (clima, dengue e água parada)
// ============================================================

// ================= IMPORTS =================
import "agents/area_risco.gaml";
import "agents/human.gaml";
import "agents/mosquito.gaml";
import "includes/dados.gaml";

// ================= GLOBAL =================
global {

    // 🔹 Arquivos externos (gerados pelos scripts Python)
    file clima_csv <- file("../Data/csv/clima_santo_amaro.csv");
    file dengue_csv <- file("../Data/csv/dengue_sao_paulo.csv");
    file agua_parada_csv <- file("../Data/csv/agua_parada_sao_paulo.csv");

    // 🔹 Tabelas lidas a partir dos arquivos CSV
    table clima_dados <- exists(clima_csv) ? read_csv(clima_csv) : table[];
    table dengue_dados <- exists(dengue_csv) ? read_csv(dengue_csv) : table[];
    table agua_parada_dados <- exists(agua_parada_csv) ? read_csv(agua_parada_csv) : table[];

    // 🔹 Variáveis climáticas (atualizadas diariamente)
    float temperatura_externa <- if (length(clima_dados) > 0) float(clima_dados at 0 get "temperatura_media") else 27.0;
    float precipitacao <- if (length(clima_dados) > 0) float(clima_dados at 0 get "chuva") else 5.0;
    float umidade <- if (length(clima_dados) > 0) float(clima_dados at 0 get "umidade") else 70.0;

    // 🔹 Parâmetros epidemiológicos
    float prob_transmissao_hum_mos <- 0.35;
    float prob_transmissao_mos_hum <- 0.45;
    int tempo_incubacao_mosquito <- 4;
    float base_taxa_reproducao_mosquito <- 0.08;
    float bonus_alagamento_reproducao <- 0.10;

    // 🔹 Geometria de Santo Amaro
    geometry santo_amaro_boundary <- envelope({-46.720, -23.660, -46.680, -23.620});
    point centro_santo_amaro <- {-46.700, -23.640};

    // 🔹 Métricas de controle
    int total_infectados_h <- 0;
    int total_recuperados <- 0;
    float r0_instantaneo <- 0.0;
    int ciclo_dia <- 0;

    // 🔹 Estruturas auxiliares
    list<point> criadouros_potenciais <- [];
    map<string, int> casos_por_distrito <- map[];
    map<string, bool> agua_parada_por_distrito <- map[];
    list<map> historico_metricas <- [];

    // ========================================================
    // 🔄 Reflexos de atualização de dados externos e ambiente
    // ========================================================

    reflex atualizar_clima {
        if (length(clima_dados) = 0) return;
        int dia_index <- cycle mod length(clima_dados);
        temperatura_externa <- float(clima_dados at dia_index get "temperatura_media");
        precipitacao <- float(clima_dados at dia_index get "chuva");
        umidade <- float(clima_dados at dia_index get "umidade");
        ciclo_dia <- ciclo_dia + 1;
        write "🌦️ Dia " + ciclo_dia + " | Temp: " + temperatura_externa + "°C | Umid: " + umidade + "% | Chuva: " + precipitacao + "mm";
    }

    reflex atualizar_dados_ambiente {
        casos_por_distrito <- map[];
        agua_parada_por_distrito <- map[];

        // Dados de dengue
        if (length(dengue_dados) > 0) {
            loop i from: 0 to: (length(dengue_dados) - 1) {
                string distrito <- (dengue_dados at i get "distrito") as string;
                int casos <- int(float(dengue_dados at i get "casos"));
                if (distrito = nil or distrito = "") continue;
                if (casos_por_distrito contains_key distrito) {
                    casos_por_distrito[distrito] <- casos_por_distrito[distrito] + casos;
                } else {
                    casos_por_distrito[distrito] <- casos;
                }
            }
        }

        // Dados de água parada / alagamentos
        if (length(agua_parada_dados) > 0) {
            loop i from: 0 to: (length(agua_parada_dados) - 1) {
                string distrito <- "";
                if (exists(agua_parada_dados at i get "REGIÃO ADMINISTRATIVA")) distrito <- (agua_parada_dados at i get "REGIÃO ADMINISTRATIVA") as string;
                if (distrito = nil or distrito = "") continue;
                agua_parada_por_distrito[distrito] <- true;
            }
        }
    }

    // ========================================================
    // 📊 Exportação de métricas diárias
    // ========================================================
    reflex exportar_metricas {
        map registro <- map[
            "dia":: ciclo_dia,
            "temperatura":: temperatura_externa,
            "chuva":: precipitacao,
            "umidade":: umidade,
            "infectados":: count(humanos where (infectado)),
            "recuperados":: count(humanos where (recuperado)),
            "mosquitos_infectivos":: count(mosquitos where (infectivo)),
            "r0":: r0_instantaneo
        ];
        historico_metricas <- historico_metricas + [registro];
        write "💾 Dia " + ciclo_dia + " exportado com sucesso.";
    }
}

// ================= INIT =================
init {
    write "🚀 Iniciando simulação da Dengue em Santo Amaro/SP...";

    // Criação das áreas de risco
    create area_risco with: [
        new area_risco(nome: "Centro Santo Amaro", geometria: circle(800) at: centro_santo_amaro, nivel_risco: 4),
        new area_risco(nome: "Margens Pinheiros", geometria: circle(600) at: {-46.710, -23.635}, nivel_risco: 5),
        new area_risco(nome: "Jardim Santo Amaro", geometria: circle(700) at: {-46.695, -23.645}, nivel_risco: 3),
        new area_risco(nome: "Vila Socorro", geometria: circle(500) at: {-46.690, -23.655}, nivel_risco: 4)
    ];

    // Criar criadouros potenciais
    loop i from: 1 to: 20 {
        point c <- any_location_in(santo_amaro_boundary);
        criadouros_potenciais <- criadouros_potenciais + [c];
    }

    // Inicializar dados ambientais
    do call (global.atualizar_dados_ambiente);
    write "✅ Modelo inicializado com dados externos.";
}
