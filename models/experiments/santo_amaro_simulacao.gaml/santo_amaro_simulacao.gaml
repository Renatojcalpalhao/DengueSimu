// ============================================================
// ARQUIVO EXPERIMENTO DA SIMULAÇÃO DA DENGUE
// Este arquivo carrega o modelo principal (dengueSim.gaml) e define a interface gráfica.
// ============================================================


experiment santo_amaro_simulacao type: gui {

    // PARÂMETROS
    parameter "População Residentes" var: pop_humanos category: "Demografia" min: 50 max: 500 default: 100;
    parameter "População Mosquitos" var: pop_mosquitos category: "Entomologia" min: 50 max: 300 default: 100;
    parameter "Transmissão M→H" var: prob_transmissao_mos_hum category: "Epidemiologia" min: 0.2 max: 0.7 default: 0.45;

    // AÇÃO INIT (É executada antes da simulação começar, reinicia os agentes)
    init {
        // (re)inicializa populações caso parâmetros sejam alterados no GUI
        clear all;
        
        // As áreas de risco são recriadas no INIT do modelo principal,
        // mas é bom garantir que elas existam antes de criar humanos
        
        // Recria as áreas de risco (elas não mudam no GUI)
        create area_risco with: [
            new area_risco(nome: "Centro Santo Amaro", geometria: circle(800) at: centro_santo_amaro, nivel_risco: 4),
            new area_risco(nome: "Margens Pinheiros", geometria: circle(600) at: {-46.710, -23.635}, nivel_risco: 5),
            new area_risco(nome: "Jardim Santo Amaro", geometria: circle(700) at: {-46.695, -23.645}, nivel_risco: 3),
            new area_risco(nome: "Vila Socorro", geometria: circle(500) at: {-46.690, -23.655}, nivel_risco: 4)
        ];
        
        // Recria os agentes com base nos parâmetros do GUI
        create humanos number: pop_humanos {
            location <- any_location_in(santo_amaro_boundary);
            localizacao_casa <- location;
            localizacao_trabalho <- location + {rnd(-2000.0, 2000.0), rnd(-2000.0, 2000.0)};
            area_residencia <- one_of(area_risco covering (location));
        }

        create mosquitos number: pop_mosquitos {
            location <- any_location_in(santo_amaro_boundary);
            criadouro <- location;
        }
        
        // Reaplica sementes de infecção
        loop i from: 1 to: 3 {
            ask one_of(humanos where (each.area_residencia.nivel_risco >= 4)) {
                infectado <- true;
                dias_infeccao <- 1;
                area_residencia.casos_reportados <- area_residencia.casos_reportados + 1;
            }
        }
    }
    
    // AÇÃO PARA ATUALIZAR MÉTRICAS (Roda a cada ciclo)
    action update_metrics {
        global.total_infectados_h <- count(humanos where (infectado));
        global.total_recuperados <- count(humanos where (recuperado));
        
        // R0 simplificado (infectados / suscetíveis)
        float suscetiveis <- max(1, float(count(humanos where (not infectado and not recuperado))));
        global.r0_instantaneo <- float(global.total_infectados_h) / suscetiveis;
    }

    // AÇÃO DIÁRIA (Chama as atualizações de clima, dados e exportação)
    action daily_update {
        // 1. ATUALIZA CLIMA
        do call(global.atualizar_clima); 
        
        // 2. ATUALIZA DADOS EPIDEMIOLÓGICOS
        do call(global.atualizar_dados_ambiente); 
        
        // 3. ATUALIZA MÉTRICAS GERAIS
        do update_metrics;
        
        // 4. EXPORTA RESULTADOS (Reflexo adicionado ao bloco Global)
        do call(global.exportar_metricas);
    }

    // ================= OUTPUT =================
    output {
        display mapa_santo_amaro {
            background #white;
            camera: global.santo_amaro_boundary;
            
            graphics "titulo" {
                draw "📍 SANTO AMARO - SÃO PAULO/SP" at: {0.1, 0.95} color: #darkblue size: 15;
                draw "Simulação de Disseminação da Dengue" at: {0.1, 0.92} color: #darkred size: 12;
            }
            
            species area_risco aspect: visual;
            
            graphics "criadouros" {
                loop ponto over: global.criadouros_potenciais {
                    draw triangle(6) at: ponto color: #cyan border: #darkblue;
                }
            }
            
            species humanos aspect: base;
            species mosquitos aspect: base;
            
            graphics "legenda" {
                draw rectangle(200,120) at: {0.02, 0.02} color: #white border: #black opacity: 0.8;
                draw "LEGENDA SANTO AMARO:" at: {0.03, 0.15} color: #black size: 10;
                draw "● Residentes" at: {0.03, 0.25} color: #gray size: 9;
                draw "● Infectados" at: {0.03, 0.35} color: #red size: 9;
                draw "● Mosquitos" at: {0.03, 0.45} color: #brown size: 9;
                draw "▲ Criadouros" at: {0.03, 0.55} color: #cyan size: 9;
                draw "Áreas Risco 4-5" at: {0.03, 0.65} color: #orange size: 9;
            }
        }
        
        display dashboard_santo_amaro {
            layout: vertical;
            
            chart curva_epidemiologica type: series title: "Curva Epidemiológica - Santo Amaro" {
                data "Infectados" value: global.total_infectados_h color: #red;
                data "Recuperados" value: global.total_recuperados color: #green;
                data "Suscetíveis" value: count(humanos where (not each.infectado and not each.recuperado)) color: #blue;
            }
            
            chart risco_areas type: series title: "Casos por Área de Risco" {
                loop area over: area_risco {
                    data area.nome value: area.casos_reportados color: 
                        area.nivel_risco = 5 ? #red :
                        area.nivel_risco = 4 ? #orange :
                        area.nivel_risco = 3 ? #yellow : #green;
                }
            }
            
            monitor "📍 Localização" value: "Santo Amaro, Zona Sul SP";
            monitor "👥 Residentes Ativos" value: count(humanos);
            monitor "🦟 População Mosquitos" value: count(mosquitos);
            monitor "🤒 Casos Ativos" value: global.total_infectados_h;
            monitor "📈 R₀ Instantâneo" value: global.r0_instantaneo;
            monitor "🌡️ Temperatura" value: global.temperatura_externa + "°C";
            monitor "💧 Precipitação" value: global.precipitacao + " mm";
            monitor "🔥 Áreas Alto Risco" value: count(area_risco where (each.nivel_risco >= 4)) + "/4";
        }
    }
    
    // LOOP PRINCIPAL: Chama a AÇÃO DIÁRIA
    loop {
        do daily_update;
        wait 1.0; // Intervalo de 1 passo entre os dias simulados
    }
}