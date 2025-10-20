species Mosquito {
    float age <- 0;
    float lifespan <- 15;
    bool infected <- false;

    reflex move {
        do move random(0.5);
    }

    reflex aging {
        age <- age + 1;
        if (age > lifespan) {
            do die;
        }
    }

    reflex bite {
        ask Human where (distance_to(self) < 0.5) {
            if (infected = true) {
                self.infected <- true;
            } else if (self.infected = true) {
                infected <- true;
            }
        }
    }
}
