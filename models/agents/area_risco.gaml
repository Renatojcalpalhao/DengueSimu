model  area_risco

species area_risco {
    string nome;
    geometry geometria;
    int nivel_risco; // 1-5
    int casos_reportados <- 0;

    aspect base {
		draw circle(3) color: #blue;
	}
}