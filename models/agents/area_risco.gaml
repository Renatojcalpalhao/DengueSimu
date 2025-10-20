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
