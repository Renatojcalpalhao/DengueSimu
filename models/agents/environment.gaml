species Environment {
    float temperature <- rnd(30) + 20;
    float humidity <- rnd(50) + 50;

    reflex weather {
        temperature <- temperature + rnd(2.0) - 1.0;
        humidity <- humidity + rnd(5.0) - 2.5;
    }
}
