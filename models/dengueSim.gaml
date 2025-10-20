model DengueSimu

global {
    // ============================
    // 🔹 Leitura de dados climáticos reais
    // ============================
    file clima_csv <- file("../data/csv/clima_santo_amaro.csv");
    table clima_dados <- read_csv(clima_csv);

    // Variáveis de clima (valores iniciais)
    float temperatura_externa <- 26.8;
    float precipitacao <- 5.0;
    float umidade <- 75.0;

    // ============================
    // 🔹 Parâmetros epidemiológicos
    // ============================
    float prob_transmissao_hum_mos <- 0.35;
    float prob_transmissao_mos_hum <- 0.45;
    int tempo_incubacao_mosquito <- 4;

    // ============================
    // 🔹 Coordenadas Santo Amaro
    // ============================
    
    geometry santo_amaro_boundary <- envelope({-46.720, -23.660, -46.680, -23.620});
    point centro_santo_amaro <- {-46.700, -23.640};

    // ============================
    // 🔹 Métricas e controle
    // ============================
    int total_infectados_h <- 0;
    int total_recuperados <- 0;
    float r0_instantaneo <- 0.0;
    int ciclo_dia <- 0;

    // ============================
    // 🔹 Listas e dados externos
    // ============================
    list<point> criadouros_potenciais <- [];
    list<string> bairros_vizinhos <- ["Socorro", "Jardim São Luís", "Campo Belo", "Jurubatuba"];

    // ============================
    // 🔹 Reflexo para atualizar clima em tempo real
    // ============================
    reflex atualizar_clima {
        int dia <- cycle mod (length(clima_dados));

        temperatura_externa <- clima_dados at dia get "temperatura_media";
        umidade <- clima_dados at dia get "umidade";
        precipitacao <- clima_dados at dia get "chuva";

        write "🌤️ Atualizando clima - Dia: " + dia
              + " | Temp: " + temperatura_externa
              + "°C | Umidade: " + umidade + "%"
              + " | Chuva: " + precipitacao + "mm";
    }
}

}

// ================= ESPÉCIES =================

// ÁREAS DE RISCO
species area_risco {
    string nome;
    geometry geometria;
    int nivel_risco; // 1-5
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

// HUMANOS
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
                area_residencia.casos_reportados <- max(0, area_residencia.casos_reportados - 1);
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

// MOSQUITOS
species mosquitos skills: [moving] {
    bool infectivo <- false;
    int dias_vida <- 0;
    int dias_infeccao <- 0;
    bool incubando <- false;

    point criadouro <- location;
    float taxa_alimentacao <- rnd(0.2, 0.4);
    int ciclo_alimentacao <- rnd(2,3);

    reflex atualizar_estado {
        dias_vida <- dias_vida + 1;
        float prob_morte <- min(0.9, dias_vida / 25.0) + 0.1;
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
                    alvo.area_residencia.casos_reportados <- alvo.area_residencia.casos_reportados + 1;
                }
            }
            if (alvo.infectado and not infectivo and not incubando) {
                if (flip(global.prob_transmissao_hum_mos)) { incubando <- true; dias_infeccao <- 0; }
            }
        }
    }

    reflex reproducao_santo_amaro {
        bool condicoes_ideais <- global.temperatura_externa between [24.0, 32.0] and global.umidade > 65.0 and global.precipitacao > 3.0;
        area_risco area_atual <- one_of(area_risco covering (location));
        float bonus_reproducao <- (area_atual != nil and area_atual.nivel_risco >= 4) ? 0.1 : 0.0;
        if (condicoes_ideais and flip(0.08 + bonus_reproducao)) {
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

    // Criar Áreas de Risco
    create area_risco with: [
        new area_risco(nome: "Centro Santo Amaro", geometria: circle(800) at: centro_santo_amaro, nivel_risco: 4),
        new area_risco(nome: "Margens Pinheiros", geometria: circle(600) at: {-46.710, -23.635}, nivel_risco: 5),
        new area_risco(nome: "Jardim Santo Amaro", geometria: circle(700) at: {-46.695, -23.645}, nivel_risco: 3),
        new area_risco(nome: "Vila Socorro", geometria: circle(500) at: {-46.690, -23.655}, nivel_risco: 4)
    ];

    // Criar Humanos
    create humanos number: 100 {
        location <- any_location_in(santo_amaro_boundary);
        localizacao_casa <- location;
        localizacao_trabalho <- location + {rnd(-2000.0, 2000.0), rnd(-2000.0, 2000.0)};
        area_residencia <- one_of(area_risco covering (location));
    }

    // Criar Mosquitos
    create mosquitos number: 100 {
        location <- any_location_in(santo_amaro_boundary);
        criadouro <- location;
    }

    // Criadouros potenciais
    loop i from: 1 to: 20 {
        point c <- any_location_in(santo_amaro_boundary);
        area_risco a <- one_of(area_risco where (each.nivel_risco >= 4));
        if (a != nil) { c <- any_location_in(a.geometria); }
        criadouros_potenciais <- criadouros_potenciais + [c];
    }

    // Casos iniciais
    loop i from: 1 to: 3 {
        ask one_of(humanos where (each.area_residencia.nivel_risco >= 4)) {
            infectado <- true;
            dias_infeccao <- 1;
            area_residencia.casos_reportados <- area_residencia.casos_reportados + 1;
        }
    }

    write "🎯 Santo Amaro: 100 residentes, 100 mosquitos, 3 casos iniciais";
}
