species Environment {
    float temperature <- rnd(30) + 20;
    float humidity <- rnd(50) + 50;

    reflex weather {
        temperature <- temperature + rnd(2.0) - 1.0;
        humidity <- humidity + rnd(5.0) - 2.5;
    }
}

// Caminhos para os dados
file clima_csv <- file("../Data/csv/clima_santo_amaro.csv");
file dengue_csv <- file("../Data/csv/dengue_sao_paulo.csv");

// Lendo os dados
csv clima_data <- read_csv(clima_csv, header: true);
csv dengue_data <- read_csv(dengue_csv, header: true);

// Mostrando na console para verificar
do println ("✅ Dados climáticos carregados: " + length(clima_data) + " registros.");
do println ("✅ Dados de dengue carregados: " + length(dengue_data) + " registros.");

global {
   list<float> temperatura_media;
   list<int> casos_dengue;
   list<string> distritos;
}

init {
   temperatura_media <- clima_data[each].temperatura_media;
   casos_dengue <- dengue_data[each].casos_confirmados;
   distritos <- dengue_data[each].distrito;
}

file ap_csv <- file("../Data/csv/agua_parada_santo_amaro.csv");
csv ap_data <- read_csv(ap_csv, header:true);
// Usa ap_data para ajustar taxa de criadouros ou zonas de risco
