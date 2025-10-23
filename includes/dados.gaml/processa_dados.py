// ======================
// ARQUIVO: includes/dados.gaml
// Funções de leitura e gravação de dados para o modelo DengueSim
// ======================

import java.io.File;
import java.io.FileWriter;
import java.io.BufferedWriter;
import java.io.IOException;

// ----- Caminhos dos dados -----
string path_dengue <- "data/dengue_data.json";
string path_agua   <- "data/agua_data.json";
string path_saida  <- "data/resultados/historico.csv";

// ----- Leitura de dados JSON -----
action carregar_dados_dengue {
    dengue_dados <- read_json(file:path_dengue);
}

action carregar_dados_agua {
    agua_dados <- read_json(file:path_agua);
}

// ----- Escrita de resultados CSV -----
action salvar_resultados {
    file f <- file(path_saida);
    if not (file_exists(path_saida)) {
        write "tick,infectados,mosquitos,chuva,agua_parada\n" to: f;
    }
    write (string(current_tick) + "," +
           string(nb_infectados) + "," +
           string(nb_mosquitos) + "," +
           string(media_chuva) + "," +
           string(media_agua_parada) + "\n") to: f;
}

// ----- Geração de gráficos -----
action gerar_graficos {
    chart "Evolução da Dengue" type:series {
        data "Infectados" value: nb_infectados color: #ff0000;
        data "Mosquitos" value: nb_mosquitos color: #00ff00;
    }
}
