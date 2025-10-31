
species humanos skills: [moving] {

    bool infectado <- false;
    bool recuperado <- false;
    bool imune <- false;

    int dias_infeccao <- 0;
    int tempo_recuperacao <- rnd(5, 8);

    point localizacao_casa <- location;
    point localizacao_trabalho <- location + {rnd(-3000, 3000), rnd(-3000, 3000)};
    bool em_casa <- true;

    float susceptibilidade <- rnd(0.6, 1.0);
    area_risco area_residencia;

    // Atualização do estado de saúde
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

    // Movimento diário entre casa e trabalho
    reflex mover {
        int hora <- cycle % 24;
        point destino;

        if (hora >= 6 and hora < 9) {
            destino <- localizacao_trabalho;
            em_casa <- false;
        } else if (hora >= 17 and hora < 20) {
            destino <- localizacao_casa;
            em_casa <- true;
        } else {
            do wander amplitude: 100.0;
            return;
        }

        if (distance_to(destino) > 10.0) {
            do goto target: destino speed: 1.5;
        }
    }

    aspect base {
        draw circle(4) color:
            (infectado ? #red :
             recuperado ? #green :
             imune ? #blue : #gray);
    }
}
