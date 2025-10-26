species humanos skills: [moving] {

    // ===================================
    // 🔹 ESTADO DE SAÚDE
    // ===================================
    bool infectado <- false;
    bool recuperado <- false;
    int dias_infeccao <- 0;
    
    // VIRÊMIA: Período em que o humano pode transmitir o vírus a um mosquito ao ser picado.
    // Tipicamente dura do dia 4 ao dia 7.
    bool viremico <- false;
    
    // VARIÁVEIS DE CONTÁGIO
    float prob_transmissao_hum_mos <- 0.4; // Prob. de transmitir para o mosquito ao ser picado
    
    // ===================================
    // 🔹 LOCALIZAÇÃO E ROTINA
    // ===================================
    point localizacao_casa;
    point localizacao_trabalho;
    area_risco area_residencia; // Referência à área de risco onde reside

    // ===================================
    // 🔹 ASPECTO VISUAL
    // ===================================
    aspect base {
        // Desenha um círculo, cuja cor depende do estado de saúde
        draw circle(5) color: (infectado ? #red : recuperado ? #green : #gray);
    }
    
    // ===================================
    // 🔹 REFLEXO: PROGRESSÃO DA DENGUE (Roda a cada ciclo/dia simulado)
    // ===================================
    reflex progressao_dengue {
        if (infectado) {
            dias_infeccao <- dias_infeccao + 1;
            
            // 1. Marca Período Virêmico (Pode infectar mosquitos)
            if (dias_infeccao >= 4 and dias_infeccao <= 7) {
                viremico <- true;
            } else {
                viremico <- false;
            }
            
            // 2. Recuperação (Fim da infecção, geralmente após 8 dias)
            if (dias_infeccao > 8) {
                infectado <- false;
                recuperado <- true; // Fica imune a novas infecções
                area_residencia.casos_reportados <- area_residencia.casos_reportados - 1; // Ajusta contagem de casos ativos
            }
        }
    }
    
    // ===================================
    // 🔹 REFLEXO: MOVIMENTO DE ROTINA (Casa/Trabalho)
    // ===================================
    reflex movimento_rotina {
        // Rotina de movimento: 50% chance de ir para casa, 50% de ir para o trabalho ou ficar
        if (rnd(1.0) < 0.5) {
            do goto target: localizacao_casa speed: 200.0;
        } else {
            do goto target: localizacao_trabalho speed: 200.0;
        }
    }
    
    // ===================================
    // 🔹 REFLEXO: REPORTAR CASO
    // ===================================
    reflex reportar_caso {
        // Reporta o caso para a área de residência apenas no primeiro dia de infecção
        if (infectado and dias_infeccao = 1) { 
            ask area_residencia {
                // Aumenta o nível de risco da área com base nos casos acumulados (exemplo de regra)
                casos_reportados <- casos_reportados + 1;
                if (casos_reportados > 10 and nivel_risco < 5) {
                    nivel_risco <- nivel_risco + 1;
                }
            }
        }
    }
}
