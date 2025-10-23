model DengueSimu

// ============================================================
// MODELO DE SIMULAÇÃO DA DENGUE - SANTO AMARO/SP
// Autores: Henrique Kioshi Yamauchi | Renato Jorge Alpalhão
// Arquivo: models/dengueSim.gaml
// ============================================================

// ===== IMPORTS: arquivos de agentes (colocar em models/agents/) =====
import "agents/area_risco.gaml";
import "agents/humanos.gaml";
import "agents/mosquitos.gaml";
import "includes/dados.gaml"

// ================= GLOBAL =================
global {

    // -------------------------
    // 🔹 Arquivos externos (CSV gerados pelos scripts Python)
    // OBS: caminhos relativos ao diretório do modelo
    // -------------------------
    file clima_csv <- file("../Data/csv/clima_santo_amaro.csv");
    file dengue_csv <- file("../Data/csv/dengue_sao_paulo.csv");
    file agua_parada_csv <- file("../Data/csv/agua_parada_sao_paulo.csv");

    // tabelas (lidas uma vez e consultadas durante a simulação)
    table clima_dados <- read_csv(clima_csv);          // esperado: data,temperatura_media,umidade,chuva
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
    float base_taxa_reproducao_mosquito <- 0.08; // probabilidade base de reprodução por ciclo
    float bonus_alagamento_reproducao <- 0.10;   // incremento da reprodução em áreas com água parada

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
    // Mapear "nome de região/distrito" para número de casos (agregado)
    map<string, int> casos_por_distrito <- map[];

    // Mapear "nome de região/distrito" para flag de água parada/alagamento (true/false)
    map<string, bool> agua_parada_por_distrito <- map[];

    // -------------------------
    // 🔹 Reflexo: Atualizar clima em tempo real (diário)
    // - Usa as linhas de clima_dados, indexadas por cycle mod length
    // -------------------------
    reflex atualizar_clima {
        if (length(clima_dados) = 0) { return; }
        int dia_index <- cycle mod length(clima_dados);
        // leitura segura usando nomes de colunas previstos
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
    //   - Agrega casos por distrito a partir do CSV dengue_dados
    //   - Marca distritos com ocorrências de alagamento / água parada
    // -------------------------
    reflex atualizar_dados_ambiente {
        // limpar mapas
        casos_por_distrito <- map[];
        agua_parada_por_distrito <- map[];

        // carregar casos de dengue (se disponível)
        if (length(dengue_dados) > 0) {
            // espera-se colunas: data, distrito (ou regioes), casos_confirmados
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
            // tenta inferir o nome do campo que indica região/distrito.
            // observar: em datasets diferentes os nomes de colunas mudam; aqui cobrimos alguns casos comuns.
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
                // marca presença de água parada para o distrito
                agua_parada_por_distrito[distrito] <- true;
            }
            write "💧 Dados água parada/alagamentos carregados - distritos marcados: " + size(agua_parada_por_distrito);
        } else {
            write "⚠️ Arquivo de água parada não encontrado ou vazio.";
        }
    }
}

// ================= SPECIES / AGENTES =================

// area_risco: áreas poligonais do modelo (bairros / zonas)
species area_risco {
    string nome;
    geometry geometria;
    int nivel_risco; // 1..5
    int casos_reportados <- 0;

    aspect visual {
        draw geometria color:
            (nivel_risco = 5 ? #red :
             nivel_risco = 4 ? #orange :
             nivel_risco = 3 ? #yellow :
             nivel_risco = 2 ? #lightgreen : #green);
        border #black;
    }
}

// humanos: comportamento diário, infecção e recuperação
species humanos skills: [moving] {
    bool infectado <- false;
    bool recuperado <- false;
    int dias_infeccao <- 0;
    bool imune <- false;

    point localizacao_casa <- location;
    point localizacao_trabalho <- location + {rnd(-3000.0, 3000.0), rnd(-3000.0, 3000.0)};
    bool em_casa <- true;

    float susceptibilidade <- rnd(0.6, 1.0);
    int tempo_recuperacao <- rnd(5, 8);

    area_risco area_residencia;
    bool usa_transporte_publico <- flip(0.7);

    reflex atualizar_saude {
        if (infectado) {
            dias_infeccao <- dias_infeccao + 1;
            if (dias_infeccao > tempo_recuperacao) {
                infectado <- false;
                recuperado <- true;
                imune <- flip(0.8);
                if (area_residencia != nil) {
                    area_residencia.casos_reportados <- max(0, area_residencia.casos_reportados - 1);
                }
            }
        }
    }

    reflex mover_santo_amaro {
        int hora_do_dia <- cycle % 24;
        point destino;

        if (hora_do_dia >= 6 and hora_do_dia < 9) {
            destino <- localizacao_trabalho;
            em_casa <- false;
        } else if (hora_do_dia >= 17 and hora_do_dia < 20) {
            destino <- localizacao_casa;
            em_casa <- true;
        } else if (hora_do_dia >= 9 and hora_do_dia < 17) {
            do wander amplitude: 200.0; return;
        } else {
            do wander amplitude: 50.0; return;
        }

        if (distance_to(destino) > 10.0) {
            float velocidade <- usa_transporte_publico ? 2.5 : 1.0;
            do goto target: destino speed: velocidade;
        }
    }

    aspect base {
        draw circle(4) color:
            infectado ? #red :
            recuperado ? #green :
            imune ? #blue : #gray;
    }
}

// mosquitos: ciclo de vida, incubação, picada, reprodução influenciada por clima/água parada
species mosquitos skills: [moving] {
    bool infectivo <- false;
    int dias_vida <- 0;
    int dias_infeccao <- 0;
    bool incubando <- false;

    point criadouro <- location;
    float taxa_alimentacao <- rnd(0.2, 0.4);
    int ciclo_alimentacao <- rnd(2,3);
    float taxa_reproducao_local <- global.base_taxa_reproducao_mosquito;

    reflex atualizar_estado {
        dias_vida <- dias_vida + 1;
        float prob_morte <- min(0.9, dias_vida / 25.0) + 0.05;
        if (flip(prob_morte)) { die(); return; }

        if (incubando) {
            dias_infeccao <- dias_infeccao + 1;
            if (dias_infeccao >= global.tempo_incubacao_mosquito) {
                infectivo <- true;
                incubando <- false;
            }
        }
    }

    reflex picar {
        if (cycle % ciclo_alimentacao != 0) return;
        humanos alvo <- one_of(humanos at_distance 20.0);
        if (alvo != nil and not alvo.recuperado) {
            if (infectivo and not alvo.infectado and not alvo.imune) {
                if (flip(global.prob_transmissao_mos_hum * alvo.susceptibilidade)) {
                    alvo.infectado <- true;
                    alvo.dias_infeccao <- 1;
                    if (alvo.area_residencia != nil) { alvo.area_residencia.casos_reportados <- alvo.area_residencia.casos_reportados + 1; }
                }
            }
            if (alvo.infectado and not infectivo and not incubando) {
                if (flip(global.prob_transmissao_hum_mos)) { incubando <- true; dias_infeccao <- 0; }
            }
        }
    }

    reflex reproducao_influenciada {
        // condições climáticas
        bool condicoes_ideais <- global.temperatura_externa between [24.0, 32.0] and global.umidade > 65.0 and global.precipitacao > 3.0;

        // verificar se estamos em área com água parada (procura pela área_risco correspondente)
        area_risco area_atual <- one_of(area_risco covering (location));
        float bonus_local <- 0.0;
        if (area_atual != nil) {
            // aumentar risco se o distrito estiver marcado como com água parada
            string nome_distrito <- area_atual.nome;
            if (global.agua_parada_por_distrito contains_key nome_distrito and global.agua_parada_por_distrito[nome_distrito]) {
                bonus_local <- bonus_local + global.bonus_alagamento_reproducao;
            }
            // também pode aumentar com base no nível de risco do bairro
            bonus_local <- bonus_local + (float(area_atual.nivel_risco - 2) * 0.02); // leve incremento por nível
        }

        float taxa_base <- base_taxa_reproducao_mosquito + bonus_local;

        if (condicoes_ideais and flip(taxa_base)) {
            create mosquitos number: rnd(1,3) {
                location <- myself.location + {rnd(-25.0,25.0)};
                criadouro <- myself.criadouro;
            }
        }
    }

    reflex mover_mosquito {
        point alvo <- nil;
        if (flip(0.8)) {
            humanos humano_proximo <- one_of(humanos at_distance 150.0);
            if (humano_proximo != nil) { alvo <- humano_proximo.location; }
        }
        if (alvo = nil) { alvo <- criadouro + {rnd(-30.0,30.0)}; }
        do goto target: alvo speed: 0.4 + rnd(0.3);
    }

    aspect base {
        draw circle(3) color:
            infectivo ? #orange :
            incubando ? #yellow : #brown;
    }
}

// ================= INIT =================
init {
    write "🔄 Iniciando simulação em Santo Amaro, Zona Sul de SP...";

    // 1) Criar Áreas de Risco (exemplos; ajuste conforme shapefile quando disponível)
    create area_risco with: [
        new area_risco(nome: "Centro Santo Amaro", geometria: circle(800) at: centro_santo_amaro, nivel_risco: 4),
        new area_risco(nome: "Margens Pinheiros", geometria: circle(600) at: {-46.710, -23.635}, nivel_risco: 5),
        new area_risco(nome: "Jardim Santo Amaro", geometria: circle(700) at: {-46.695, -23.645}, nivel_risco: 3),
        new area_risco(nome: "Vila Socorro", geometria: circle(500) at: {-46.690, -23.655}, nivel_risco: 4)
    ];

    // 2) Criar Humanos
    create humanos number: 100 {
        location <- any_location_in(santo_amaro_boundary);
        localizacao_casa <- location;
        localizacao_trabalho <- location + {rnd(-2000.0, 2000.0), rnd(-2000.0, 2000.0)};
        area_residencia <- one_of(area_risco covering (location));
    }

    // 3) Criar Mosquitos
    create mosquitos number: 100 {
        location <- any_location_in(santo_amaro_boundary);
        criadouro <- location;
    }

    // 4) Criadouros potenciais aleatórios
    loop i from: 1 to: 20 {
        point c <- any_location_in(santo_amaro_boundary);
        area_risco a <- one_of(area_risco where (each.nivel_risco >= 4));
        if (a != nil) { c <- any_location_in(a.geometria); }
        criadouros_potenciais <- criadouros_potenciais + [c];
    }

    // 5) Inicializar mapas com dados externos (casos por distrito e água parada)
    // chama reflex atualizar_dados_ambiente uma vez ao iniciar
    do actualizar <- call (global.atualizar_dados_ambiente);

    // Aplicar casos carregados para ajustar area_risco.casos_reportados (se houver correspondência de nome)
    if (size(casos_por_distrito) > 0) {
        // tenta casar nomes de area_risco com chaves do mapa (pode requerer harmonização manual)
        ask area_risco {
            if (global.casos_por_distrito contains_key each.nome) {
                each.casos_reportados <- global.casos_por_distrito[each.nome];
            }
        }
    }

    // 6) Criar casos iniciais (seed)
    loop i from: 1 to: 3 {
        ask one_of(humanos where (each.area_residencia.nivel_risco >= 4)) {
            infectado <- true;
            dias_infeccao <- 1;
            area_residencia.casos_reportados <- area_residencia.casos_reportados + 1;
        }
    }

    write "🎯 Santo Amaro: " + count(humanos) + " residentes, " + count(mosquitos) + " mosquitos, " + " casos iniciais: 3";
}

// ================= EXPERIMENT (GUI) =================
experiment santo_amaro_simulacao type: gui {

    parameter "População Inicial (Humanos)" type: int default: 100 min: 10;
    parameter "População Inicial (Mosquitos)" type: int default: 100 min: 10;
    parameter "Ciclos por dia" type: int default: 1 min: 1;

    init {
        // (re)inicializa populações caso parâmetros sejam alterados no GUI
        // limpar e recriar conforme parâmetros
        clear all;

        create humanos number: População_Inicial__Humanos {
            location <- any_location_in(santo_amaro_boundary);
            localizacao_casa <- location;
            localizacao_trabalho <- location + {rnd(-2000.0, 2000.0), rnd(-2000.0, 2000.0)};
            area_residencia <- one_of(area_risco covering (location));
        }

        create mosquitos number: População_Inicial__Mosquitos {
            location <- any_location_in(santo_amaro_boundary);
            criadouro <- location;
        }

        // Reaplica sementes
        loop i from: 1 to: 3 {
            ask one_of(humanos where (each.area_residencia.nivel_risco >= 4)) {
                infectado <- true;
                dias_infeccao <- 1;
                area_residencia.casos_reportados <- area_residencia.casos_reportados + 1;
            }
        }
    }

    // ação que atualiza métricas (pode ser chamada a cada ciclo)
    action update_metrics {
        total_infectados_h <- count(humanos where (infectado));
        total_recuperados <- count(humanos where (recuperado));
        // R0 simplificado (infectados / suscetíveis)
        float suscetiveis <- max(1, float(count(humanos where (not infectado and not recuperado))));
        r0_instantaneo <- float(total_infectados_h) / suscetiveis;
    }

    // action para atualizar clima/dados externos a cada N ciclos (por exemplo diariamente)
    action daily_update {
        // chama os reflexos globais para atualizar clima e dados ambiente
        do call(global.atualizar_clima);
        do call(global.atualizar_dados_ambiente);
    }

    // DISPLAY: mapa + dashboard
    output {
        display sim_mapa {
            width: 800; height: 600;
            // mostrar limites
            layer {
                draw santo_amaro_boundary color: #f0f0f0;
            }
            // areas
            species area_risco color: (a.nivel_risco >= 4 ? #ffaaaa : #dddddd) border: #000;
            // humanos
            species humanos color: (a.infectado ? #ff0000 : a.recuperado ? #00aa00 : #8888ff) size: 4;
            // mosquitos
            species mosquitos color: (a.infectivo ? #ff8000 : a.incubando ? #ffff66 : #996633) size: 2;
            // criadouros
            layer {
                draw for: criadouros_potenciais {
                    draw circle(3) at: each color: #0000ff alpha: 0.6;
                }
            }
        }

        display dashboard {
            layout: vertical;
            // curva epidemiológica
            chart curva_seir type: series {
                data "Infectados" value: count(humanos where (infectado));
                data "Recuperados" value: count(humanos where (recuperado));
                data "Suscetíveis" value: count(humanos where (not infectado and not recuperado));
            }
            monitor "R0 Instantâneo" value: r0_instantaneo;
            monitor "Casos Atuais" value: total_infectados_h;
            monitor "Temperatura (°C)" value: temperatura_externa;
            monitor "Precipitação (mm)" value: precipitacao;
            monitor "Umidade (%)" value: umidade;
        }
    }
}
