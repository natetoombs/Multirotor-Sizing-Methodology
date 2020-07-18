% 

function comboOPList = getOperatingPoints(comboList, thrustHover, thrustMax, BattCellNo)
    for i = 1:size(comboList,2)
        specs = loadSpecCurves(comboList(i));
        powerHover_prev = 99999;
        for j = 1:size(specs,2)
            speedHover = interp1(specs(j).Thrust, specs(j).RPM, thrustHover);
            speedMax = interp1(specs(j).Thrust, specs(j).RPM, thrustMax);
            speedLimit = comboList(i).speedLimit;
            if speedMax <= speedLimit
                thrustLimit = interp1(specs(j).RPM, specs(j).Thrust, speedLimit);
                powerHover = interp1(specs(j).RPM, specs(j).Power, speedHover); % Eq. (13)
                powerMax = interp1(specs(j).RPM, specs(j).Power, speedMax);
                powerLimit = interp1(specs(j).RPM, specs(j).Power, speedLimit);
                if powerHover < powerHover_prev && (BattCellNo == 0 || BattCellNo*3.85 == specs(j).Voltage)
                    powerHover_prev = powerHover;
                    comboList(i).powerHover = powerHover;
                    comboList(i).powerMax = powerMax;
                    comboList(i).speedHover = speedHover;
                    comboList(i).speedMax = speedMax;
                    comboList(i).thrustHover = thrustHover;
                    comboList(i).thrustMax = thrustMax;
                    comboList(i).voltage = specs(j).Voltage;
                end
            end
        end
        comboOPList = comboList;
    end
end