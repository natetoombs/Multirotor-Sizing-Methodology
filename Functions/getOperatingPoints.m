% For a given combo list, each combo has data loaded from loadSpecCurves.m
% If there are multiple instances of a combo in the data, the specs
% variable will have a data instance for each. Only the data instance with
% the lowest power at hover will be kept with the combo.
%
% The interpolations contain data from 0 to 100% throttle.
%
% output = comboOPList array (see Combo.m)

function comboOPList = getOperatingPoints(comboList, thrustHover, thrustMax, BattCellNo)
    for i = 1:size(comboList,2)
        specs = loadSpecCurves(comboList(i));
        powerHover_prev = 99999;
        for j = 1:size(specs,2)
            speedHover = interp1(specs(j).Thrust, specs(j).RPM, thrustHover);
            speedMax = interp1(specs(j).Thrust, specs(j).RPM, thrustMax);
            speedLimit = comboList(i).speedLimit;
            if speedMax <= speedLimit
                powerHover = interp1(specs(j).RPM, specs(j).Power, speedHover); % Eq. (13)
                powerMax = interp1(specs(j).RPM, specs(j).Power, speedMax);
                if powerHover < powerHover_prev && (BattCellNo == 0 || BattCellNo == roundBatteryCellNo(specs(j).Voltage/3.7))
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