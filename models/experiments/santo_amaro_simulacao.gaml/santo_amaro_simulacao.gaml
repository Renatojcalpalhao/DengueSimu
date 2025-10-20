experiment santo_amaro_simulacao type: gui {
    
    parameter "População Residentes" var: pop_humanos category: "Demografia" min: 50 max: 500 default: 100;
    parameter "População Mosquitos" var: pop_mosquitos category: "Entomologia" min: 50 max: 300 default: 100;
    parameter "Temperatura Média (°C)" var: temperatura_externa category: "Clima" min: 20.0 max: 32.0 default: 26.8;
    parameter "Precipitação (mm)" var: precipitacao category: "Clima" min: 0.0 max: 40.0 default: 8.5;
    parameter "Transmissão M→H" var: prob_transmissao_mos_hum category: "Epidemiologia" min: 0.2 max: 0.7 default: 0.45;
    
    output mapa_santo_amaro {
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
    
    output dashboard_santo_amaro {
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
    
    loop {
        do global.atualizar_dados_externos;
        do global.atualizar_metricas;
        wait 1.0;
    }
}
