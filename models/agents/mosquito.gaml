

species mosquitos skills: [moving] {

    bool infectivo <- false;
    bool incubando <- false;
    int dias_vida <- 0;
    int dias_infeccao <- 0;
    point criadouro <- location;

   reflex atualizar_estado {
        dias_vida <- dias_vida + 1;

        // Morte natural (~25 dias)
        if (dias_vida > 25) {
            die();
        }

        // Incubação do vírus (extrínseca)
        if (incubando) {
            dias_infeccao <- dias_infeccao + 1;
            if (dias_infeccao >= global.tempo_incubacao_mosquito) {
                infectivo <- true;
                incubando <- false;
            }
        }
    }

   reflex picar {
        humanos alvo <- one_of(humanos at_distance 10.0);
        if (alvo != nil) {
            if (infectivo and not alvo.infectado and not alvo.imune) {
                if (flip(global.prob_transmissao_mos_hum * alvo.susceptibilidade)) {
                    alvo.infectado <- true;
                    alvo.dias_infeccao <- 1;
                    alvo.area_residencia.casos_reportados <- alvo.area_residencia.casos_reportados + 1;
                }
            }
            if (alvo.infectado and not infectivo and not incubando) {
                if (flip(global.prob_transmissao_hum_mos)) {
                    incubando <- true;
                    dias_infeccao <- 0;
                }
            }
        }
    }

    reflex reproducao {
        bool condicoes_favoraveis <- (global.temperatura_externa between [24.0, 32.0])
                                      and (global.umidade > 65.0)
                                      and (global.precipitacao > 3.0);

        if (condicoes_favoraveis and flip(global.base_taxa_reproducao_mosquito)) {
            create mosquitos number: rnd(1,3) {
                location <- myself.location + {rnd(-20,20)};
                criadouro <- myself.criadouro;
            }
        }
    }

    reflex mover {
        point destino <- criadouro + {rnd(-30,30)};
        do goto target: destino speed: 0.5;
    }

    aspect base {
        draw circle(3) color:
            (infectivo ? #orange :
             incubando ? #yellow : #brown);
    }
}
