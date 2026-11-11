# P12 balance simulation report

This deterministic, no-render model runs three fixed strategies (balanced, splash/control, and elite focus) across ten seeds each. It is a tuning signal based on game data, not a substitute for device playtests.

| Level | Mode | Win rate | Target | Avg HP | Avg time | Dominant loss wave | Recommendation |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| 1-1 | easy | 100% | 90% | 30.0 | 217.1s | 0 | Within the ±10-point review band. |
| 1-1 | normal | 100% | 65% | 20.0 | 217.1s | 0 | data/levels/world01/level01.json, wave 1: grunt count 7 -> 8. |
| 1-1 | hard | 100% | 35% | 8.5 | 255.1s | 0 | data/levels/world01/level01.json, wave 1: grunt count 7 -> 8. |
| 1-2 | easy | 100% | 90% | 30.0 | 215.1s | 0 | Within the ±10-point review band. |
| 1-2 | normal | 100% | 65% | 20.0 | 215.1s | 0 | data/levels/world01/level02.json, wave 1: grunt count 7 -> 8. |
| 1-2 | hard | 100% | 35% | 8.4 | 254.0s | 0 | data/levels/world01/level02.json, wave 1: grunt count 7 -> 8. |
| 1-3 | easy | 100% | 90% | 30.0 | 213.8s | 0 | Within the ±10-point review band. |
| 1-3 | normal | 100% | 65% | 20.0 | 213.8s | 0 | data/levels/world01/level03.json, wave 1: swarmling count 9 -> 11. |
| 1-3 | hard | 100% | 35% | 10.0 | 251.8s | 0 | data/levels/world01/level03.json, wave 1: swarmling count 9 -> 11. |
| 1-4 | easy | 100% | 90% | 30.0 | 214.4s | 0 | Within the ±10-point review band. |
| 1-4 | normal | 100% | 65% | 20.0 | 214.4s | 0 | data/levels/world01/level04.json, wave 1: grunt count 6 -> 7. |
| 1-4 | hard | 100% | 35% | 9.2 | 260.1s | 0 | data/levels/world01/level04.json, wave 1: grunt count 6 -> 7. |
| 2-1 | easy | 100% | 90% | 30.0 | 90.9s | 0 | Within the ±10-point review band. |
| 2-1 | normal | 100% | 65% | 20.0 | 90.9s | 0 | data/levels/world02/level01.json, wave 1: bat count 6 -> 7. |
| 2-1 | hard | 100% | 35% | 9.3 | 141.8s | 0 | data/levels/world02/level01.json, wave 1: bat count 6 -> 7. |
| 2-2 | easy | 100% | 90% | 30.0 | 95.3s | 0 | Within the ±10-point review band. |
| 2-2 | normal | 100% | 65% | 19.0 | 95.3s | 0 | data/levels/world02/level02.json, wave 1: scarab count 7 -> 8. |
| 2-2 | hard | 100% | 35% | 4.4 | 147.9s | 0 | data/levels/world02/level02.json, wave 1: scarab count 7 -> 8. |
| 2-3 | easy | 100% | 90% | 30.0 | 96.2s | 0 | Within the ±10-point review band. |
| 2-3 | normal | 100% | 65% | 20.0 | 96.2s | 0 | data/levels/world02/level03.json, wave 1: bat count 10 -> 12. |
| 2-3 | hard | 97% | 35% | 4.5 | 144.6s | 5 | data/levels/world02/level03.json, wave 5: scarab count 9 -> 11. |
| 2-4 | easy | 100% | 90% | 30.0 | 97.6s | 0 | Within the ±10-point review band. |
| 2-4 | normal | 100% | 65% | 16.8 | 98.9s | 0 | data/levels/world02/level04.json, wave 1: scarab count 9 -> 11. |
| 2-4 | hard | 83% | 35% | 1.6 | 151.6s | 4 | data/levels/world02/level04.json, wave 4: scarab count 8 -> 9. |
| 2-5 | easy | 100% | 80% | 30.0 | 107.7s | 0 | data/levels/world02/level05.json, wave 1: bat count 12 -> 14. |
| 2-5 | normal | 100% | 50% | 19.6 | 107.7s | 0 | data/levels/world02/level05.json, wave 1: bat count 12 -> 14. |
| 2-5 | hard | 60% | 20% | 2.6 | 134.7s | 2 | data/levels/world02/level05.json, wave 2: scarab count 10 -> 12. |
| 2-6 | easy | 100% | 90% | 29.9 | 100.3s | 0 | Within the ±10-point review band. |
| 2-6 | normal | 100% | 65% | 14.8 | 109.3s | 0 | data/levels/world02/level06.json, wave 1: scarab count 11 -> 13. |
| 2-6 | hard | 33% | 35% | 0.7 | 94.0s | 1 | Within the ±10-point review band. |
| 2-7 | easy | 100% | 90% | 30.0 | 100.8s | 0 | Within the ±10-point review band. |
| 2-7 | normal | 100% | 65% | 13.7 | 128.5s | 0 | data/levels/world02/level07.json, wave 1: bat count 14 -> 16. |
| 2-7 | hard | 0% | 35% | 0.0 | 98.6s | 2 | data/levels/world02/level07.json, wave 2: scarab count 12 -> 11. |
| 2-8 | easy | 100% | 90% | 28.9 | 102.6s | 0 | Within the ±10-point review band. |
| 2-8 | normal | 100% | 65% | 11.5 | 117.6s | 0 | data/levels/world02/level08.json, wave 1: scarab count 13 -> 15. |
| 2-8 | hard | 0% | 35% | 0.0 | 61.8s | 1 | data/levels/world02/level08.json, wave 1: scarab count 13 -> 12. |
| 2-9 | easy | 100% | 90% | 30.0 | 103.2s | 0 | Within the ±10-point review band. |
| 2-9 | normal | 100% | 65% | 15.6 | 105.1s | 0 | data/levels/world02/level09.json, wave 1: bat count 17 -> 20. |
| 2-9 | hard | 33% | 35% | 0.7 | 84.6s | 1 | Within the ±10-point review band. |
| 2-10 | easy | 100% | 80% | 30.0 | 110.5s | 0 | data/levels/world02/level10.json, wave 1: bat count 16 -> 18. |
| 2-10 | normal | 100% | 50% | 16.0 | 115.2s | 0 | data/levels/world02/level10.json, wave 1: bat count 16 -> 18. |
| 2-10 | hard | 0% | 20% | 0.0 | 83.7s | 2 | data/levels/world02/level10.json, wave 2: scarab count 14 -> 13. |
| 3-1 | easy | 100% | 90% | 30.0 | 92.2s | 0 | Within the ±10-point review band. |
| 3-1 | normal | 100% | 65% | 20.0 | 92.2s | 0 | data/levels/world03/level01.json, wave 1: swamp_shaman count 5 -> 6. |
| 3-1 | hard | 100% | 35% | 8.8 | 132.6s | 0 | data/levels/world03/level01.json, wave 1: swamp_shaman count 5 -> 6. |
| 3-2 | easy | 100% | 90% | 30.0 | 96.8s | 0 | Within the ±10-point review band. |
| 3-2 | normal | 100% | 65% | 19.4 | 96.8s | 0 | data/levels/world03/level02.json, wave 1: spore_splitter count 8 -> 9. |
| 3-2 | hard | 100% | 35% | 4.6 | 147.2s | 0 | data/levels/world03/level02.json, wave 1: spore_splitter count 8 -> 9. |
| 3-3 | easy | 100% | 90% | 30.0 | 98.0s | 0 | Within the ±10-point review band. |
| 3-3 | normal | 100% | 65% | 20.0 | 98.0s | 0 | data/levels/world03/level03.json, wave 1: poison_spitter count 9 -> 11. |
| 3-3 | hard | 83% | 35% | 2.8 | 128.9s | 2 | data/levels/world03/level03.json, wave 2: spore_splitter count 9 -> 11. |
| 3-4 | easy | 100% | 90% | 30.0 | 100.0s | 0 | Within the ±10-point review band. |
| 3-4 | normal | 100% | 65% | 19.0 | 100.5s | 0 | data/levels/world03/level04.json, wave 1: spore_splitter count 10 -> 12. |
| 3-4 | hard | 93% | 35% | 2.5 | 152.2s | 2 | data/levels/world03/level04.json, wave 2: swamp_shaman count 9 -> 11. |
| 3-5 | easy | 100% | 80% | 30.0 | 109.0s | 0 | data/levels/world03/level05.json, wave 1: poison_spitter count 10 -> 12. |
| 3-5 | normal | 100% | 50% | 20.0 | 109.0s | 0 | data/levels/world03/level05.json, wave 1: poison_spitter count 10 -> 12. |
| 3-5 | hard | 93% | 20% | 4.0 | 168.7s | 2 | data/levels/world03/level05.json, wave 2: spore_splitter count 10 -> 12. |
| 3-6 | easy | 100% | 90% | 30.0 | 102.5s | 0 | Within the ±10-point review band. |
| 3-6 | normal | 100% | 65% | 18.5 | 103.7s | 0 | data/levels/world03/level06.json, wave 1: swamp_shaman count 11 -> 13. |
| 3-6 | hard | 33% | 35% | 0.9 | 102.2s | 2 | Within the ±10-point review band. |
| 3-7 | easy | 100% | 90% | 30.0 | 103.8s | 0 | Within the ±10-point review band. |
| 3-7 | normal | 100% | 65% | 14.1 | 136.4s | 0 | data/levels/world03/level07.json, wave 1: spore_splitter count 13 -> 15. |
| 3-7 | hard | 0% | 35% | 0.0 | 57.7s | 1 | data/levels/world03/level07.json, wave 1: spore_splitter count 13 -> 12. |
| 3-8 | easy | 100% | 90% | 30.0 | 104.7s | 0 | Within the ±10-point review band. |
| 3-8 | normal | 100% | 65% | 16.0 | 108.5s | 0 | data/levels/world03/level08.json, wave 1: poison_spitter count 14 -> 16. |
| 3-8 | hard | 0% | 35% | 0.0 | 51.2s | 1 | data/levels/world03/level08.json, wave 1: poison_spitter count 14 -> 13. |
| 3-9 | easy | 100% | 90% | 30.0 | 106.1s | 0 | Within the ±10-point review band. |
| 3-9 | normal | 100% | 65% | 13.8 | 114.2s | 0 | data/levels/world03/level09.json, wave 1: spore_splitter count 15 -> 17. |
| 3-9 | hard | 0% | 35% | 0.0 | 50.1s | 1 | data/levels/world03/level09.json, wave 1: spore_splitter count 15 -> 14. |
| 3-10 | easy | 100% | 80% | 30.0 | 112.5s | 0 | data/levels/world03/level10.json, wave 1: poison_spitter count 14 -> 16. |
| 3-10 | normal | 100% | 50% | 16.7 | 118.5s | 0 | data/levels/world03/level10.json, wave 1: poison_spitter count 14 -> 16. |
| 3-10 | hard | 0% | 20% | 0.0 | 89.6s | 2 | data/levels/world03/level10.json, wave 2: spore_splitter count 14 -> 13. |
| 4-1 | easy | 100% | 90% | 30.0 | 94.2s | 0 | Within the ±10-point review band. |
| 4-1 | normal | 100% | 65% | 19.5 | 96.3s | 0 | data/levels/world04/level01.json, wave 1: ice_wolf count 8 -> 9. |
| 4-1 | hard | 30% | 35% | 0.5 | 86.5s | 2 | Within the ±10-point review band. |
| 4-2 | easy | 100% | 90% | 29.9 | 97.8s | 0 | Within the ±10-point review band. |
| 4-2 | normal | 100% | 65% | 11.6 | 108.6s | 0 | data/levels/world04/level02.json, wave 1: ice_knight count 7 -> 8. |
| 4-2 | hard | 0% | 35% | 0.0 | 44.6s | 1 | data/levels/world04/level02.json, wave 1: ice_knight count 7 -> 7. |
| 4-3 | easy | 100% | 90% | 30.0 | 99.2s | 0 | Within the ±10-point review band. |
| 4-3 | normal | 100% | 65% | 12.3 | 108.2s | 0 | data/levels/world04/level03.json, wave 1: ice_wolf count 14 -> 16. |
| 4-3 | hard | 0% | 35% | 0.0 | 48.7s | 1 | data/levels/world04/level03.json, wave 1: ice_wolf count 14 -> 13. |
| 4-4 | easy | 100% | 90% | 28.5 | 100.0s | 0 | Within the ±10-point review band. |
| 4-4 | normal | 100% | 65% | 5.8 | 118.8s | 0 | data/levels/world04/level04.json, wave 1: ice_knight count 9 -> 11. |
| 4-4 | hard | 0% | 35% | 0.0 | 54.9s | 1 | data/levels/world04/level04.json, wave 1: ice_knight count 9 -> 9. |
| 4-5 | easy | 100% | 80% | 30.0 | 108.6s | 0 | data/levels/world04/level05.json, wave 1: ice_wolf count 16 -> 18. |
| 4-5 | normal | 100% | 50% | 10.9 | 123.2s | 0 | data/levels/world04/level05.json, wave 1: ice_wolf count 16 -> 18. |
| 4-5 | hard | 0% | 20% | 0.0 | 44.8s | 1 | data/levels/world04/level05.json, wave 1: ice_wolf count 16 -> 15. |
| 4-6 | easy | 100% | 90% | 25.7 | 103.9s | 0 | Within the ±10-point review band. |
| 4-6 | normal | 33% | 65% | 1.7 | 82.8s | 1 | data/levels/world04/level06.json, wave 1: ice_knight count 11 -> 10. |
| 4-6 | hard | 0% | 35% | 0.0 | 74.7s | 1 | data/levels/world04/level06.json, wave 1: ice_knight count 11 -> 10. |
| 4-7 | easy | 100% | 90% | 27.4 | 112.2s | 0 | Within the ±10-point review band. |
| 4-7 | normal | 0% | 65% | 0.0 | 73.9s | 2 | data/levels/world04/level07.json, wave 2: ice_knight count 12 -> 11. |
| 4-7 | hard | 0% | 35% | 0.0 | 56.5s | 1 | data/levels/world04/level07.json, wave 1: ice_wolf count 19 -> 18. |
| 4-8 | easy | 100% | 90% | 20.0 | 112.1s | 0 | Within the ±10-point review band. |
| 4-8 | normal | 0% | 65% | 0.0 | 53.0s | 1 | data/levels/world04/level08.json, wave 1: ice_knight count 13 -> 12. |
| 4-8 | hard | 0% | 35% | 0.0 | 90.5s | 1 | data/levels/world04/level08.json, wave 1: ice_knight count 13 -> 12. |
| 4-9 | easy | 100% | 90% | 29.2 | 103.7s | 0 | Within the ±10-point review band. |
| 4-9 | normal | 23% | 65% | 1.1 | 84.1s | 2 | data/levels/world04/level09.json, wave 2: ice_knight count 14 -> 13. |
| 4-9 | hard | 0% | 35% | 0.0 | 61.0s | 1 | data/levels/world04/level09.json, wave 1: ice_wolf count 21 -> 19. |
| 4-10 | easy | 100% | 80% | 29.9 | 110.7s | 0 | data/levels/world04/level10.json, wave 1: ice_wolf count 20 -> 23. |
| 4-10 | normal | 33% | 50% | 2.5 | 96.9s | 2 | data/levels/world04/level10.json, wave 2: ice_knight count 14 -> 13. |
| 4-10 | hard | 0% | 20% | 0.0 | 48.3s | 1 | data/levels/world04/level10.json, wave 1: ice_wolf count 20 -> 18. |
| 5-1 | easy | 100% | 90% | 30.0 | 97.1s | 0 | Within the ±10-point review band. |
| 5-1 | normal | 100% | 65% | 17.6 | 100.0s | 0 | data/levels/world05/level01.json, wave 1: wraith count 8 -> 9. |
| 5-1 | hard | 3% | 35% | 0.0 | 89.4s | 3 | data/levels/world05/level01.json, wave 3: wraith count 11 -> 10. |
| 5-2 | easy | 100% | 90% | 30.0 | 101.0s | 0 | Within the ±10-point review band. |
| 5-2 | normal | 100% | 65% | 14.7 | 110.9s | 0 | data/levels/world05/level02.json, wave 1: wraith count 12 -> 14. |
| 5-2 | hard | 0% | 35% | 0.0 | 51.7s | 1 | data/levels/world05/level02.json, wave 1: wraith count 12 -> 11. |
| 5-3 | easy | 100% | 90% | 30.0 | 103.0s | 0 | Within the ±10-point review band. |
| 5-3 | normal | 100% | 65% | 16.8 | 108.5s | 0 | data/levels/world05/level03.json, wave 1: necro_acolyte count 8 -> 9. |
| 5-3 | hard | 0% | 35% | 0.0 | 65.1s | 2 | data/levels/world05/level03.json, wave 2: wraith count 15 -> 14. |
| 5-4 | easy | 100% | 90% | 29.9 | 105.5s | 0 | Within the ±10-point review band. |
| 5-4 | normal | 100% | 65% | 9.7 | 123.1s | 0 | data/levels/world05/level04.json, wave 1: wraith count 16 -> 18. |
| 5-4 | hard | 0% | 35% | 0.0 | 61.9s | 1 | data/levels/world05/level04.json, wave 1: wraith count 16 -> 15. |
| 5-5 | easy | 100% | 80% | 28.8 | 114.7s | 0 | data/levels/world05/level05.json, wave 1: wraith count 18 -> 21. |
| 5-5 | normal | 100% | 50% | 7.0 | 136.4s | 0 | data/levels/world05/level05.json, wave 1: wraith count 18 -> 21. |
| 5-5 | hard | 0% | 20% | 0.0 | 67.8s | 1 | data/levels/world05/level05.json, wave 1: wraith count 18 -> 17. |
| 5-6 | easy | 100% | 90% | 30.0 | 107.3s | 0 | Within the ±10-point review band. |
| 5-6 | normal | 87% | 65% | 7.0 | 123.5s | 3 | data/levels/world05/level06.json, wave 3: wraith count 18 -> 21. |
| 5-6 | hard | 0% | 35% | 0.0 | 88.8s | 2 | data/levels/world05/level06.json, wave 2: wraith count 20 -> 18. |
| 5-7 | easy | 100% | 90% | 19.8 | 123.5s | 0 | Within the ±10-point review band. |
| 5-7 | normal | 0% | 65% | 0.0 | 87.7s | 1 | data/levels/world05/level07.json, wave 1: wraith count 22 -> 20. |
| 5-7 | hard | 0% | 35% | 0.0 | 88.3s | 1 | data/levels/world05/level07.json, wave 1: wraith count 22 -> 20. |
| 5-8 | easy | 100% | 90% | 28.2 | 110.8s | 0 | Within the ±10-point review band. |
| 5-8 | normal | 33% | 65% | 1.4 | 97.1s | 2 | data/levels/world05/level08.json, wave 2: wraith count 24 -> 22. |
| 5-8 | hard | 0% | 35% | 0.0 | 58.7s | 1 | data/levels/world05/level08.json, wave 1: necro_acolyte count 13 -> 12. |
| 5-9 | easy | 100% | 90% | 19.4 | 118.0s | 0 | Within the ±10-point review band. |
| 5-9 | normal | 0% | 65% | 0.0 | 58.9s | 1 | data/levels/world05/level09.json, wave 1: wraith count 25 -> 23. |
| 5-9 | hard | 0% | 35% | 0.0 | 101.3s | 1 | data/levels/world05/level09.json, wave 1: wraith count 25 -> 23. |
| 5-10 | easy | 100% | 80% | 26.5 | 118.4s | 0 | data/levels/world05/level10.json, wave 1: wraith count 24 -> 27. |
| 5-10 | normal | 0% | 50% | 0.0 | 104.0s | 5 | data/bosses/morthal.json: HP 7800 -> 7020. |
| 5-10 | hard | 0% | 20% | 0.0 | 77.3s | 1 | data/levels/world05/level10.json, wave 1: wraith count 24 -> 22. |
| 6-1 | easy | 100% | 90% | 30.0 | 96.6s | 0 | Within the ±10-point review band. |
| 6-1 | normal | 100% | 65% | 18.4 | 98.9s | 0 | data/levels/world06/level01.json, wave 1: infiltrator count 8 -> 9. |
| 6-1 | hard | 13% | 35% | 0.2 | 72.9s | 2 | data/levels/world06/level01.json, wave 2: magma_golem count 5 -> 5. |
| 6-2 | easy | 100% | 90% | 30.0 | 101.3s | 0 | Within the ±10-point review band. |
| 6-2 | normal | 100% | 65% | 18.9 | 103.6s | 0 | data/levels/world06/level02.json, wave 1: bomber_imp count 12 -> 14. |
| 6-2 | hard | 3% | 35% | 0.0 | 79.6s | 3 | data/levels/world06/level02.json, wave 3: magma_golem count 7 -> 7. |
| 6-3 | easy | 100% | 90% | 26.2 | 103.8s | 0 | Within the ±10-point review band. |
| 6-3 | normal | 100% | 65% | 6.0 | 125.0s | 0 | data/levels/world06/level03.json, wave 1: magma_golem count 8 -> 9. |
| 6-3 | hard | 0% | 35% | 0.0 | 65.1s | 1 | data/levels/world06/level03.json, wave 1: magma_golem count 8 -> 8. |
| 6-4 | easy | 100% | 90% | 30.0 | 105.1s | 0 | Within the ±10-point review band. |
| 6-4 | normal | 100% | 65% | 7.2 | 113.6s | 0 | data/levels/world06/level04.json, wave 1: infiltrator count 17 -> 20. |
| 6-4 | hard | 0% | 35% | 0.0 | 44.5s | 1 | data/levels/world06/level04.json, wave 1: infiltrator count 17 -> 16. |
| 6-5 | easy | 100% | 80% | 30.0 | 114.4s | 0 | data/levels/world06/level05.json, wave 1: bomber_imp count 19 -> 22. |
| 6-5 | normal | 100% | 50% | 13.7 | 119.8s | 0 | data/levels/world06/level05.json, wave 1: bomber_imp count 19 -> 22. |
| 6-5 | hard | 0% | 20% | 0.0 | 50.0s | 1 | data/levels/world06/level05.json, wave 1: bomber_imp count 19 -> 18. |
| 6-6 | easy | 100% | 90% | 20.6 | 115.3s | 0 | Within the ±10-point review band. |
| 6-6 | normal | 0% | 65% | 0.0 | 67.7s | 1 | data/levels/world06/level06.json, wave 1: magma_golem count 11 -> 10. |
| 6-6 | hard | 0% | 35% | 0.0 | 96.1s | 1 | data/levels/world06/level06.json, wave 1: magma_golem count 11 -> 10. |
| 6-7 | easy | 100% | 90% | 16.5 | 120.6s | 0 | Within the ±10-point review band. |
| 6-7 | normal | 0% | 65% | 0.0 | 84.2s | 2 | data/levels/world06/level07.json, wave 2: magma_golem count 12 -> 11. |
| 6-7 | hard | 0% | 35% | 0.0 | 60.2s | 1 | data/levels/world06/level07.json, wave 1: infiltrator count 22 -> 20. |
| 6-8 | easy | 100% | 90% | 28.2 | 111.1s | 0 | Within the ±10-point review band. |
| 6-8 | normal | 27% | 65% | 0.8 | 88.2s | 2 | data/levels/world06/level08.json, wave 2: magma_golem count 13 -> 12. |
| 6-8 | hard | 0% | 35% | 0.0 | 49.6s | 1 | data/levels/world06/level08.json, wave 1: bomber_imp count 23 -> 21. |
| 6-9 | easy | 100% | 90% | 28.9 | 110.2s | 0 | Within the ±10-point review band. |
| 6-9 | normal | 0% | 65% | 0.0 | 69.0s | 2 | data/levels/world06/level09.json, wave 2: magma_golem count 14 -> 13. |
| 6-9 | hard | 0% | 35% | 0.0 | 66.3s | 1 | data/levels/world06/level09.json, wave 1: infiltrator count 25 -> 23. |
| 6-10 | easy | 100% | 80% | 29.2 | 117.2s | 0 | data/levels/world06/level10.json, wave 1: infiltrator count 24 -> 27. |
| 6-10 | normal | 3% | 50% | 0.0 | 93.3s | 2 | data/levels/world06/level10.json, wave 2: magma_golem count 15 -> 14. |
| 6-10 | hard | 0% | 20% | 0.0 | 52.2s | 1 | data/levels/world06/level10.json, wave 1: infiltrator count 24 -> 22. |
| 7-1 | easy | 100% | 90% | 28.8 | 99.4s | 0 | Within the ±10-point review band. |
| 7-1 | normal | 93% | 65% | 4.9 | 119.5s | 3 | data/levels/world07/level01.json, wave 3: machine_soldier count 10 -> 12. |
| 7-1 | hard | 0% | 35% | 0.0 | 52.6s | 1 | data/levels/world07/level01.json, wave 1: machine_soldier count 8 -> 8. |
| 7-2 | easy | 100% | 90% | 30.0 | 103.2s | 0 | Within the ±10-point review band. |
| 7-2 | normal | 93% | 65% | 9.1 | 110.8s | 4 | data/levels/world07/level02.json, wave 4: machine_soldier count 13 -> 15. |
| 7-2 | hard | 0% | 35% | 0.0 | 69.4s | 2 | data/levels/world07/level02.json, wave 2: machine_soldier count 11 -> 10. |
| 7-3 | easy | 100% | 90% | 29.9 | 106.3s | 0 | Within the ±10-point review band. |
| 7-3 | normal | 63% | 65% | 5.7 | 116.3s | 3 | Within the ±10-point review band. |
| 7-3 | hard | 0% | 35% | 0.0 | 55.1s | 1 | data/levels/world07/level03.json, wave 1: tesla_bot count 11 -> 10. |
| 7-4 | easy | 100% | 90% | 19.7 | 113.4s | 0 | Within the ±10-point review band. |
| 7-4 | normal | 0% | 65% | 0.0 | 53.4s | 1 | data/levels/world07/level04.json, wave 1: machine_soldier count 15 -> 14. |
| 7-4 | hard | 0% | 35% | 0.0 | 91.5s | 1 | data/levels/world07/level04.json, wave 1: machine_soldier count 15 -> 14. |
| 7-5 | easy | 100% | 80% | 29.8 | 114.0s | 0 | data/levels/world07/level05.json, wave 1: swarm_drone count 22 -> 25. |
| 7-5 | normal | 67% | 50% | 4.6 | 104.5s | 2 | data/levels/world07/level05.json, wave 2: machine_soldier count 14 -> 16. |
| 7-5 | hard | 0% | 20% | 0.0 | 53.2s | 1 | data/levels/world07/level05.json, wave 1: swarm_drone count 22 -> 20. |
| 7-6 | easy | 100% | 90% | 19.4 | 112.9s | 0 | Within the ±10-point review band. |
| 7-6 | normal | 0% | 65% | 0.0 | 57.0s | 1 | data/levels/world07/level06.json, wave 1: tesla_bot count 14 -> 13. |
| 7-6 | hard | 0% | 35% | 0.0 | 77.2s | 1 | data/levels/world07/level06.json, wave 1: tesla_bot count 14 -> 13. |
| 7-7 | easy | 33% | 90% | 4.3 | 106.0s | 3 | data/levels/world07/level07.json, wave 3: machine_soldier count 16 -> 15. |
| 7-7 | normal | 0% | 65% | 0.0 | 71.2s | 1 | data/levels/world07/level07.json, wave 1: machine_soldier count 19 -> 18. |
| 7-7 | hard | 0% | 35% | 0.0 | 121.9s | 1 | data/levels/world07/level07.json, wave 1: machine_soldier count 19 -> 18. |
| 7-8 | easy | 90% | 90% | 15.8 | 124.2s | 3 | Within the ±10-point review band. |
| 7-8 | normal | 0% | 65% | 0.0 | 53.7s | 1 | data/levels/world07/level08.json, wave 1: tesla_bot count 16 -> 15. |
| 7-8 | hard | 0% | 35% | 0.0 | 92.2s | 1 | data/levels/world07/level08.json, wave 1: tesla_bot count 16 -> 15. |
| 7-9 | easy | 100% | 90% | 17.4 | 116.2s | 0 | Within the ±10-point review band. |
| 7-9 | normal | 0% | 65% | 0.0 | 78.9s | 2 | data/levels/world07/level09.json, wave 2: machine_soldier count 21 -> 19. |
| 7-9 | hard | 0% | 35% | 0.0 | 48.1s | 1 | data/levels/world07/level09.json, wave 1: swarm_drone count 29 -> 27. |
| 7-10 | easy | 97% | 80% | 9.0 | 126.5s | 1 | data/levels/world07/level10.json, wave 1: machine_soldier count 20 -> 23. |
| 7-10 | normal | 0% | 50% | 0.0 | 62.7s | 1 | data/levels/world07/level10.json, wave 1: machine_soldier count 20 -> 18. |
| 7-10 | hard | 0% | 20% | 0.0 | 107.3s | 1 | data/levels/world07/level10.json, wave 1: machine_soldier count 20 -> 18. |
| 8-1 | easy | 100% | 90% | 30.0 | 99.4s | 0 | Within the ±10-point review band. |
| 8-1 | normal | 100% | 65% | 17.0 | 101.5s | 0 | data/levels/world08/level01.json, wave 1: sky_carrier count 5 -> 6. |
| 8-1 | hard | 3% | 35% | 0.0 | 78.7s | 3 | data/levels/world08/level01.json, wave 3: sky_carrier count 6 -> 6. |
| 8-2 | easy | 100% | 90% | 30.0 | 103.6s | 0 | Within the ±10-point review band. |
| 8-2 | normal | 100% | 65% | 17.6 | 104.1s | 0 | data/levels/world08/level02.json, wave 1: swarm_drone count 20 -> 23. |
| 8-2 | hard | 0% | 35% | 0.0 | 45.7s | 1 | data/levels/world08/level02.json, wave 1: swarm_drone count 20 -> 18. |
| 8-3 | easy | 100% | 90% | 29.8 | 105.3s | 0 | Within the ±10-point review band. |
| 8-3 | normal | 100% | 65% | 9.3 | 115.8s | 0 | data/levels/world08/level03.json, wave 1: sky_carrier count 8 -> 9. |
| 8-3 | hard | 0% | 35% | 0.0 | 49.7s | 1 | data/levels/world08/level03.json, wave 1: sky_carrier count 8 -> 8. |
| 8-4 | easy | 100% | 90% | 30.0 | 107.0s | 0 | Within the ±10-point review band. |
| 8-4 | normal | 100% | 65% | 12.8 | 111.0s | 0 | data/levels/world08/level04.json, wave 1: swarm_drone count 26 -> 30. |
| 8-4 | hard | 0% | 35% | 0.0 | 40.7s | 1 | data/levels/world08/level04.json, wave 1: swarm_drone count 26 -> 24. |
| 8-5 | easy | 100% | 80% | 28.9 | 115.8s | 0 | data/levels/world08/level05.json, wave 1: sky_carrier count 10 -> 12. |
| 8-5 | normal | 100% | 50% | 6.3 | 133.5s | 0 | data/levels/world08/level05.json, wave 1: sky_carrier count 10 -> 12. |
| 8-5 | hard | 0% | 20% | 0.0 | 60.0s | 1 | data/levels/world08/level05.json, wave 1: sky_carrier count 10 -> 9. |
| 8-6 | easy | 100% | 90% | 30.0 | 107.8s | 0 | Within the ±10-point review band. |
| 8-6 | normal | 63% | 65% | 5.8 | 100.5s | 2 | Within the ±10-point review band. |
| 8-6 | hard | 0% | 35% | 0.0 | 48.5s | 1 | data/levels/world08/level06.json, wave 1: swarm_drone count 30 -> 27. |
| 8-7 | easy | 100% | 90% | 25.2 | 114.7s | 0 | Within the ±10-point review band. |
| 8-7 | normal | 0% | 65% | 0.0 | 96.5s | 1 | data/levels/world08/level07.json, wave 1: sky_carrier count 11 -> 10. |
| 8-7 | hard | 0% | 35% | 0.0 | 69.9s | 1 | data/levels/world08/level07.json, wave 1: sky_carrier count 11 -> 10. |
| 8-8 | easy | 100% | 90% | 29.7 | 109.6s | 0 | Within the ±10-point review band. |
| 8-8 | normal | 33% | 65% | 2.2 | 80.5s | 1 | data/levels/world08/level08.json, wave 1: swarm_drone count 34 -> 31. |
| 8-8 | hard | 0% | 35% | 0.0 | 56.9s | 1 | data/levels/world08/level08.json, wave 1: swarm_drone count 34 -> 31. |
| 8-9 | easy | 100% | 90% | 23.0 | 114.6s | 0 | Within the ±10-point review band. |
| 8-9 | normal | 27% | 65% | 0.5 | 75.5s | 1 | data/levels/world08/level09.json, wave 1: sky_carrier count 13 -> 12. |
| 8-9 | hard | 0% | 35% | 0.0 | 82.6s | 1 | data/levels/world08/level09.json, wave 1: sky_carrier count 13 -> 12. |
| 8-10 | easy | 100% | 80% | 26.6 | 116.5s | 0 | data/levels/world08/level10.json, wave 1: sky_carrier count 12 -> 14. |
| 8-10 | normal | 13% | 50% | 0.1 | 119.4s | 5 | data/bosses/zephyra.json: HP 12500 -> 11250. |
| 8-10 | hard | 0% | 20% | 0.0 | 63.8s | 1 | data/levels/world08/level10.json, wave 1: sky_carrier count 12 -> 11. |
| 9-1 | easy | 100% | 90% | 30.0 | 98.9s | 0 | Within the ±10-point review band. |
| 9-1 | normal | 100% | 65% | 11.4 | 106.2s | 0 | data/levels/world09/level01.json, wave 1: void_walker count 8 -> 9. |
| 9-1 | hard | 0% | 35% | 0.0 | 40.0s | 1 | data/levels/world09/level01.json, wave 1: void_walker count 8 -> 8. |
| 9-2 | easy | 100% | 90% | 30.0 | 104.4s | 0 | Within the ±10-point review band. |
| 9-2 | normal | 100% | 65% | 10.7 | 113.1s | 0 | data/levels/world09/level02.json, wave 1: void_leech count 10 -> 12. |
| 9-2 | hard | 0% | 35% | 0.0 | 77.6s | 2 | data/levels/world09/level02.json, wave 2: void_walker count 14 -> 13. |
| 9-3 | easy | 100% | 90% | 22.1 | 111.5s | 0 | Within the ±10-point review band. |
| 9-3 | normal | 0% | 65% | 0.0 | 48.6s | 1 | data/levels/world09/level03.json, wave 1: void_walker count 17 -> 16. |
| 9-3 | hard | 0% | 35% | 0.0 | 83.5s | 1 | data/levels/world09/level03.json, wave 1: void_walker count 17 -> 16. |
| 9-4 | easy | 100% | 90% | 29.6 | 110.5s | 0 | Within the ±10-point review band. |
| 9-4 | normal | 33% | 65% | 2.6 | 85.4s | 2 | data/levels/world09/level04.json, wave 2: void_walker count 20 -> 18. |
| 9-4 | hard | 0% | 35% | 0.0 | 55.7s | 1 | data/levels/world09/level04.json, wave 1: void_leech count 14 -> 13. |
| 9-5 | easy | 90% | 80% | 13.5 | 116.6s | 1 | Within the ±10-point review band. |
| 9-5 | normal | 0% | 50% | 0.0 | 58.9s | 1 | data/levels/world09/level05.json, wave 1: void_walker count 22 -> 20. |
| 9-5 | hard | 0% | 20% | 0.0 | 101.2s | 1 | data/levels/world09/level05.json, wave 1: void_walker count 22 -> 20. |
| 9-6 | easy | 100% | 90% | 25.1 | 115.4s | 0 | Within the ±10-point review band. |
| 9-6 | normal | 0% | 65% | 0.0 | 79.6s | 2 | data/levels/world09/level06.json, wave 2: void_walker count 23 -> 21. |
| 9-6 | hard | 0% | 35% | 0.0 | 65.1s | 1 | data/levels/world09/level06.json, wave 1: void_leech count 18 -> 17. |
| 9-7 | easy | 10% | 90% | 0.2 | 87.9s | 1 | data/levels/world09/level07.json, wave 1: void_walker count 26 -> 24. |
| 9-7 | normal | 0% | 65% | 0.0 | 74.7s | 1 | data/levels/world09/level07.json, wave 1: void_walker count 26 -> 24. |
| 9-7 | hard | 0% | 35% | 0.0 | 128.4s | 1 | data/levels/world09/level07.json, wave 1: void_walker count 26 -> 24. |
| 9-8 | easy | 67% | 90% | 14.5 | 103.1s | 2 | data/levels/world09/level08.json, wave 2: void_walker count 29 -> 27. |
| 9-8 | normal | 0% | 65% | 0.0 | 81.0s | 2 | data/levels/world09/level08.json, wave 2: void_walker count 29 -> 27. |
| 9-8 | hard | 0% | 35% | 0.0 | 84.8s | 1 | data/levels/world09/level08.json, wave 1: void_leech count 22 -> 20. |
| 9-9 | easy | 0% | 90% | 0.0 | 48.3s | 1 | data/levels/world09/level09.json, wave 1: void_walker count 31 -> 28. |
| 9-9 | normal | 0% | 65% | 0.0 | 91.2s | 1 | data/levels/world09/level09.json, wave 1: void_walker count 31 -> 28. |
| 9-9 | hard | 0% | 35% | 0.0 | 156.7s | 1 | data/levels/world09/level09.json, wave 1: void_walker count 31 -> 28. |
| 9-10 | easy | 47% | 80% | 5.8 | 80.9s | 1 | data/levels/world09/level10.json, wave 1: void_walker count 28 -> 26. |
| 9-10 | normal | 0% | 50% | 0.0 | 66.8s | 1 | data/levels/world09/level10.json, wave 1: void_walker count 28 -> 26. |
| 9-10 | hard | 0% | 20% | 0.0 | 114.8s | 1 | data/levels/world09/level10.json, wave 1: void_walker count 28 -> 26. |
| 10-1 | easy | 100% | 90% | 27.0 | 101.7s | 0 | Within the ±10-point review band. |
| 10-1 | normal | 33% | 65% | 2.4 | 85.8s | 1 | data/levels/world10/level01.json, wave 1: demon_berserker count 12 -> 11. |
| 10-1 | hard | 0% | 35% | 0.0 | 65.8s | 1 | data/levels/world10/level01.json, wave 1: demon_berserker count 12 -> 11. |
| 10-2 | easy | 100% | 90% | 21.4 | 108.5s | 0 | Within the ±10-point review band. |
| 10-2 | normal | 0% | 65% | 0.0 | 47.8s | 1 | data/levels/world10/level02.json, wave 1: demon_berserker count 15 -> 14. |
| 10-2 | hard | 0% | 35% | 0.0 | 82.3s | 1 | data/levels/world10/level02.json, wave 1: demon_berserker count 15 -> 14. |
| 10-3 | easy | 100% | 90% | 29.2 | 105.5s | 0 | Within the ±10-point review band. |
| 10-3 | normal | 43% | 65% | 2.7 | 92.1s | 2 | data/levels/world10/level03.json, wave 2: demon_berserker count 16 -> 15. |
| 10-3 | hard | 0% | 35% | 0.0 | 39.6s | 1 | data/levels/world10/level03.json, wave 1: ice_wolf count 22 -> 20. |
| 10-4 | easy | 100% | 90% | 27.4 | 105.6s | 0 | Within the ±10-point review band. |
| 10-4 | normal | 27% | 65% | 0.7 | 82.1s | 2 | data/levels/world10/level04.json, wave 2: demon_berserker count 18 -> 17. |
| 10-4 | hard | 0% | 35% | 0.0 | 45.1s | 1 | data/levels/world10/level04.json, wave 1: wraith count 18 -> 17. |
| 10-5 | easy | 100% | 90% | 26.6 | 109.0s | 0 | Within the ±10-point review band. |
| 10-5 | normal | 20% | 65% | 0.5 | 76.6s | 2 | data/levels/world10/level05.json, wave 2: demon_berserker count 20 -> 18. |
| 10-5 | hard | 0% | 35% | 0.0 | 60.4s | 1 | data/levels/world10/level05.json, wave 1: bomber_imp count 22 -> 20. |
| 10-6 | easy | 100% | 90% | 18.5 | 117.0s | 0 | Within the ±10-point review band. |
| 10-6 | normal | 0% | 65% | 0.0 | 71.2s | 2 | data/levels/world10/level06.json, wave 2: demon_berserker count 21 -> 19. |
| 10-6 | hard | 0% | 35% | 0.0 | 39.2s | 1 | data/levels/world10/level06.json, wave 1: swarm_drone count 28 -> 26. |
| 10-7 | easy | 10% | 90% | 0.2 | 98.5s | 3 | data/levels/world10/level07.json, wave 3: demon_berserker count 20 -> 18. |
| 10-7 | normal | 0% | 65% | 0.0 | 80.6s | 2 | data/levels/world10/level07.json, wave 2: demon_berserker count 22 -> 20. |
| 10-7 | hard | 0% | 35% | 0.0 | 65.8s | 1 | data/levels/world10/level07.json, wave 1: sky_carrier count 12 -> 11. |
| 10-8 | easy | 33% | 90% | 2.8 | 71.4s | 1 | data/levels/world10/level08.json, wave 1: void_walker count 25 -> 23. |
| 10-8 | normal | 0% | 65% | 0.0 | 74.5s | 1 | data/levels/world10/level08.json, wave 1: void_walker count 25 -> 23. |
| 10-8 | hard | 0% | 35% | 0.0 | 128.0s | 1 | data/levels/world10/level08.json, wave 1: void_walker count 25 -> 23. |
| 10-9 | easy | 0% | 90% | 0.0 | 45.6s | 1 | data/levels/world10/level09.json, wave 1: demon_berserker count 26 -> 24. |
| 10-9 | normal | 0% | 65% | 0.0 | 86.1s | 1 | data/levels/world10/level09.json, wave 1: demon_berserker count 26 -> 24. |
| 10-9 | hard | 0% | 35% | 0.0 | 148.0s | 1 | data/levels/world10/level09.json, wave 1: demon_berserker count 26 -> 24. |
| 10-10 | easy | 37% | 80% | 2.2 | 70.7s | 1 | data/levels/world10/level10.json, wave 1: demon_berserker count 26 -> 24. |
| 10-10 | normal | 0% | 50% | 0.0 | 68.4s | 1 | data/levels/world10/level10.json, wave 1: demon_berserker count 26 -> 24. |
| 10-10 | hard | 0% | 20% | 0.0 | 117.7s | 1 | data/levels/world10/level10.json, wave 1: demon_berserker count 26 -> 24. |

## Release blocker
Missing level data: 1-5, 1-6, 1-7, 1-8, 1-9, 1-10. The campaign currently has 94/100 level files, so it does not meet the PRD's 100-level release criterion.
