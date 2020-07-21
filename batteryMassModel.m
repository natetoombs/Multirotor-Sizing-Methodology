% Battery Mass Model

power = [251.600 60.495 236.800 161.32 96.2 488.4 355.2 244.2 473.6 325.6 651.2 19.24 74 48.84 111 137.64 488.4 91.76 666 488.4 148];
mass  = [1294 354 1332 919 639 2530 1992 1270 2652 1690 3370 155 586 385 838 835 2464 583 3673 2650 1066];

model = fitlm(power,mass);

figure(1); clf;
scatter(power,mass)
hold on
plot(model)
title("Battery Mass per Watt Hour")
xlabel("Capacity (Wh)")
ylabel("Mass (g)")