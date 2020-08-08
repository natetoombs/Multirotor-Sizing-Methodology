

%  output = {Combo, Hover Time, WOT Time, Total Mass, Wh};
function output = multirotorSizingAlgorithm(p)
    %% User Parameters
    RotorNo = p.RotorNo;
    Coaxial = p.Coaxial;
    OptimizationGoal = p.OptimizationGoal;
    ThrustWeightRatio = p.ThrustWeightRatio;
    PropDiameter_Min = p.PropDiameter_Min;
    if p.useWheelbase
        if RotorNo == 4 && Coaxial == false || RotorNo == 8 && Coaxial == true
            PropDiameter_Max = p.Wheelbase/sqrt(2);
        elseif RotorNo == 6 && Coaxial == false || RotorNo == 12 && Coaxial == true
            PropDiameter_Max = p.Wheelbase/2;
        elseif RotorNo == 8 && Coaxial == false || RotorNo == 16 && Coaxial == true
            PropDiameter_Max = p.Wheelbase*sin(pi/8);
        else
            disp('Problem with Wheelbase calculation; using PropDiameter_Max');
            PropDiameter_Max = p.PropDiameter_Max;
        end
    else
        PropDiameter_Max = p.PropDiameter_Max;
    end
    
    if p.useOverlap % Use the numeric solver
        d = sym('d');
        PropDiameter_Max = vpasolve(p.Overlap == 1/pi*(2*acos(PropDiameter_Max/d)-sin(2*acos(PropDiameter_Max/d))), d, PropDiameter_Max*(1 + p.Overlap));
        PropDiameter_Max = round(double(PropDiameter_Max), 3);
    end
    SafetyFactor = 1.00; % [1-2], arbitrary safety parameter
    
    % Battery Specs
    BattCapacity_Wh = p.Wh; % Desired Watt Hours

    if p.SelectBattCellNo
        BattCellNo_Desired = p.BattCellNo_Desired;
    else
        BattCellNo_Desired = 0;
    end
    
    mass_Combo_Est = p.mass_Combo_Est;
    mass_Battery_Total = BattCapacity_Wh*5.0782 + 130.88; % See batteryMassModel.m
    mass_NoDrive_Est = p.mass_NoDrive_Est;
    mass_Total_Est = mass_NoDrive_Est + RotorNo*mass_Combo_Est + mass_Battery_Total;

    %% Load and Filter Combo List
    comboList = loadComboList();
    filteredComboList = filterComboList(comboList, PropDiameter_Min, PropDiameter_Max,...
        mass_Combo_Est*2); % Take up to 200% combo mass
    
    if isempty(filteredComboList)
        disp(['Empty Combo List for ' num2str(BattCapacity_Wh) ' Watt Hours.']);
        output = {0 0 0 mass_Total_Est p.Wh};
        return
    end
    %% Get Operating Points
    if Coaxial
        thrustHover_Est = 1/0.85*mass_Total_Est/RotorNo; % calculate thrust/motor required for hover
    else
        thrustHover_Est = mass_Total_Est/RotorNo; % calculate thrust/motor required for hover
    end
    thrustMax_Est = thrustHover_Est*ThrustWeightRatio;
    OPcomboList = getOperatingPoints(filteredComboList, thrustHover_Est, ...
        thrustMax_Est, BattCellNo_Desired);

    %% Find most efficient combo
    powerHover_prev = 9999; % Initialize
    for i = 1:size(OPcomboList,2)
        if OPcomboList(i).powerHover < powerHover_prev
            powerHover_prev = OPcomboList(i).powerHover;
            comboChosen = OPcomboList(i);
        end
    end

    if ~exist('comboChosen','var')
        disp(['No matching combination found for ' num2str(BattCapacity_Wh) ' Watt Hours.']);
        output = {0 0 0 mass_Total_Est p.Wh};
        return
    end

    %% Determine battery specification, total mass
    BattCellVoltage = 3.7; % V per cell
    BattCellNo = roundBatteryCellNo(comboChosen.voltage/3.7); % Round to the nearest even number
    BattVoltageSagConstant = 0.5/0.8*BattCellNo;
    BattCapacity_Ah = BattCapacity_Wh/(BattCellNo*3.7);
    minBattRating = comboChosen.powerMax/comboChosen.voltage*RotorNo*SafetyFactor/BattCapacity_Ah;
    BattPeukertConstant = 1.3; % n; for LiPo, Peukert's constant for selected type of battery
    BattHourRating = 1; % h

    mass_Total = mass_NoDrive_Est + RotorNo*comboChosen.massCombined + mass_Battery_Total;

    %% Calculate initial battery state
    voltage_hover(1) = BattCellNo*4.2;
    voltage_max(1) = BattCellNo*4.2;
    current_hover(1) = comboChosen.powerHover/voltage_hover(1)*RotorNo; % calculate total current at hover
    current_max(1) = comboChosen.powerMax/voltage_max(1)*RotorNo; % calculate total current at WOT
    capacity_hover(1) = (current_hover(1)^(1-BattPeukertConstant))*(BattHourRating^(1-BattPeukertConstant))*(BattCapacity_Ah^BattPeukertConstant); % from modified Peukert's equation calculate available capacity at hover
    capacity_max(1) = (current_max(1)^(1-BattPeukertConstant))*(BattHourRating^(1-BattPeukertConstant))*(BattCapacity_Ah^BattPeukertConstant); % from modified Peukert's equation calculate available capacity at WOT

    %% Calculate next flight iterations
    timeStep = 1/60/60; % set timestep as 1 s
    ii = 1;
    while voltage_hover(ii) > BattCellVoltage*BattCellNo && ii*timeStep < 2
        voltage_hover(ii+1) = voltage_hover(1) - (BattVoltageSagConstant/capacity_hover(1))*(capacity_hover(1) - capacity_hover(ii)); % calculate instantaneus voltage including voltage sag
        current_hover(ii+1) = comboChosen.powerHover*RotorNo/voltage_hover(ii+1); % calculate instantaneus current based on required power for hover
        capacity_hover(ii+1) = (current_hover(ii+1)^(1-BattPeukertConstant))*(BattHourRating^(1-BattPeukertConstant))*(BattCapacity_Ah^BattPeukertConstant) - sum(current_hover(2:end)*timeStep); % calculate remaining available capacity according to Paeukert's effect
        ii = ii+1;
    end
    time_hover = (0:ii-1)*timeStep; % calculate time spent in hover

    ii = 1;
    while voltage_max(ii) > BattCellVoltage*BattCellNo && ii*timeStep < 2
        voltage_max(ii+1) = voltage_max(1) - (BattVoltageSagConstant/capacity_max(1))*(capacity_max(1) - capacity_max(ii)); % calculate instantaneus voltage including voltage sag
        current_max(ii+1) = comboChosen.powerMax*RotorNo/voltage_max(ii+1); % calculate instantaneus current based on estimated power at WOT
        capacity_max(ii+1) = (current_max(ii+1)^(1-BattPeukertConstant))*(BattHourRating^(1-BattPeukertConstant))*(BattCapacity_Ah^BattPeukertConstant) - sum(current_max(2:end)*timeStep); % calculate remaining available capacity according to Paeukert's effect
        ii = ii+1;
    end
    time_max = (0:ii-1)*timeStep; % calculate time spent at WOT
    
    output = {comboChosen, time_hover(end)*60, time_max(end)*60, mass_Total, BattCapacity_Wh};

    
    %% Display results and plot characteristics
    if p.DisplayResults == true
        disp(['For a ' num2str(RotorNo) '-rotor drone with estimated AUM of ' num2str(round(mass_Total_Est)) ' g (calculated TOM of ' num2str(round(mass_Total)) ' g):']);

        switch OptimizationGoal
            case 'hover'
                textOptimization = ['the highest specific thrust of ' num2str(round(comboChosen.thrustHover/comboChosen.powerHover*100)/100)  ' gf/W per motor at hover.'];
            case 'max'
                textOptimization = ['the highest specific thrust of ' num2str(round(propChosen.OPmax(2)/powerChosen.powerMax*100)/100)  ' gf/W per motor at WOT.'];
            case 'utilization'
                textOptimization = 'maximum usable power range of propeller';
            otherwise
                error('ERROR! Wrong optimization criteria!');
        end

        disp(['The ' comboChosen.propName ' propeller should be chosen for ' textOptimization]);
        disp(['The ' comboChosen.motorName ' motor should be selected, controlled by a ' num2str(ceil(comboChosen.currentRating)) ' A ESC per motor.']);
        disp(['One motor uses ' num2str(round(comboChosen.powerHover)) ' W of electrical power at hover and ' num2str(round(comboChosen.powerMax)) ' W of electrical power at WOT.']);
        disp(['The whole system should be powered by ' num2str(BattCellNo) 'S ' num2str(ceil(minBattRating)) 'C LiPo batteries of '...
            num2str(round(BattCapacity_Ah*1000, -3)) ' mAh (having a mass of about ' num2str(mass_Battery_Total/1000) ' kg).']);
        disp(['This configuration should achieve around ' num2str(round(time_hover(end)*60)) ' min of hover and around ' num2str(round(time_max(end)*60)) ' min of flight at WOT.']);
        disp('---------');

    end

    function filteredComboList = filterComboList(comboList, PDmin, PDmax, Mmax)
        filteredComboList = [];
        for k = 1:size(comboList,2)
            if comboList(k).propDiameter <= PDmax && comboList(k).propDiameter...
                    >= PDmin && comboList(k).massCombined <= Mmax
                filteredComboList = [filteredComboList, comboList(k)];
            end
        end
    end
end