model Santo_Amaro_20d

import "../dengueSim.gaml"

experiment santo_amaro_20d parent: DengueSimu type: gui {

    parameter "População inicial de humanos" var: nb_humanos default: 100;
    parameter "População inicial de mosquitos" var: nb_mosquitos default: 150;
    parameter "Duração da simulação (dias)" var: duracao_simulacao default: 20;

    output {
        display mapa_simulacao {
            species humanos color: (each.infectado ? #red : each.recuperado ? #green : #blue);
            species mosquitos color: (each.infectivo ? #orange : #gray);
            species area_risco border: #black color:
                (each.nivel_risco = 5 ? #red :
                 each.nivel_risco = 4 ? #orange :
                 each.nivel_risco = 3 ? #yellow :
                 each.nivel_risco = 2 ? #lightgreen : #green);
        }

        display graficos {

            chart "Casos de Dengue" type: series {
                data "Infectados" value: count(humanos where (infectado)) color: #red;
                data "Recuperados" value: count(humanos where (recuperado)) color: #green;
                data "Suscetíveis" value: count(humanos where (not infectado and not recuperado)) color: #blue;
            }

            chart "Clima" type: series {
                data "Temperatura (°C)" value: temperatura_externa color: #orange;
                data "Chuva (mm)" value: precipitacao color: #blue;
                data "Umidade (%)" value: umidade color: #aqua;
            }

            chart "Mosquitos" type: series {
                data "Total Infectivos" value: count(mosquitos where (infectivo)) color: #purple;
                data "Total" value: count(mosquitos) color: #gray;
            }

            monitor "R₀ Instantâneo" value: r0_instantaneo;
            monitor "Total Infectados" value: total_infectados_h;
        }
    }

    // === AÇÃO PRINCIPAL DE EXECUÇÃO DIÁRIA ===
    reflex atualizar_diario every: 1 {
        do atualizar_clima;
        do atualizar_dados_ambiente;
        do exportar_metricas;
    }
}
