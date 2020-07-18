% Use motor/propeller combinations from KDE, T-Motor


close all; clear, clc;
format compact; format shortG;

%% User Parameters
RotorNo = 6; % Number of rotors
Coaxial = false; % Coaxial motors have 15% loss
OptimisationGoal = 'hover'; % selection criteria
                    % hover - best specific thrust (g/W) at hover
                    % max - best specific thrust (g/W) at 100% throttle
                    % utilisation - maximum usable power range of propeller
ThrustWeightRatio = 1.75; % estimator for maximum performance
                    % 2 - minimum
                    % 3 - payload transport
                    % 4 - surveillence
                    % 5+ - aerobatics / hi-speed video
                    % 7+ - racing
PropDiameter_Min = 10; % inch, min. propeller diameter
PropDiameter_Max = 14; % inch, max. propeller diameter
SafetyFactor = 1.00; % [1-2], arbitrary safety parameter

%% Battery Specs TODO: Move this elsewhere

BattCapacity_Wh = 50; % Desired Watt Hours

SelectBattCellNo = false;
if SelectBattCellNo
    BattCellNo_Desired = 10;
else
    BattCellNo_Desired = 0;
end

%% Mass data [g] %TODO: Customize, add computer/GPS weight
mass_Frame = 1400; % Estimate for large frame = 3000
mass_FC = 0; % Ignore
mass_FC_GPS = 0; % Ignore
mass_FC_CurrentSensor = 0; % Ignore
mass_Receiver = 0; % Ignore
mass_ESC_Est = 0; % Ignore
mass_Motor_Est = 100; % set max motor mass/ea to 150% Est
mass_Propeller_Est = 40; % max prop mass %TODO
mass_Combo_Est = mass_Motor_Est + mass_Propeller_Est;
mass_Payload = 4500; % 20 lbs = 9000, 50 lbs = 23000
mass_Battery_Total = BattCapacity_Wh*4.992 + 242;
mass_Other_Est = 0; % Ignore

mass_NoDrive_Est = mass_Frame + mass_FC + mass_FC_GPS + mass_FC_CurrentSensor + mass_Receiver + mass_Payload + mass_Other_Est;
mass_Total_Est = mass_NoDrive_Est + RotorNo*(mass_Motor_Est + mass_ESC_Est + mass_Propeller_Est) + mass_Battery_Total;

%% Load and Filter Combo List
comboList = loadComboList();
filteredComboList = filterComboList(comboList, PropDiameter_Min, PropDiameter_Max,...
    mass_Combo_Est);

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

if ~exist('comboChosen')
    error('ERROR! No matching combination found!');
end

%% Determine battery specification, total mass
BattCellVoltage = 3.7; % V per cell, battery cell voltage
BattCellNo = comboChosen.voltage/3.85; %TODO: FIX THE 3.85
BattVoltageSagConstant = 0.5/0.8*BattCellNo;
BattCapacity_Ah = BattCapacity_Wh/(BattCellNo*3.7);
minBattRating = comboChosen.powerMax/comboChosen.voltage*RotorNo*SafetyFactor/BattCapacity_Ah;
BattPeukertConstant = 1.3; % n; for LiPo, Peukert's constant for selected type of battery
BattHourRating = 1; % h

mass_ESC = mass_ESC_Est;
mass_Total = mass_NoDrive_Est + RotorNo*(comboChosen.massCombined + mass_ESC) + mass_Battery_Total;

%% Calculate initial battery state
voltage_hover(1) = BattCellNo*4.2; % %TODO: DO something with that 3.85; 4.2 V per cell times number of cells
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

%% Display results and plot characteristics
disp(['For a ' num2str(RotorNo) '-rotor drone with estimated AUM of ' num2str(round(mass_Total_Est)) ' g (calculated TOM of ' num2str(round(mass_Total)) ' g):']);

switch OptimisationGoal
    case 'hover'
        textOptimisation = ['the highest specific thrust of ' num2str(round(comboChosen.thrustHover/comboChosen.powerHover*100)/100)  ' gf/W per motor at hover.'];
    case 'max'
        textOptimisation = ['the highest specific thrust of ' num2str(round(propChosen.OPmax(2)/powerChosen.powerMax*100)/100)  ' gf/W per motor at WOT.'];
    case 'utilisation'
        textOptimisation = 'maximum usable power range of propeller';
    otherwise
        error('ERROR! Wrong optimisation criteria!');
end
        
disp(['The ' comboChosen.propName ' propeller should be chosen for ' textOptimisation]);
disp(['The ' comboChosen.motorName ' motor should be selected with '...
    '(TORQUE) ' ' Nm torque at maximum speed of ' num2str(round(comboChosen.speedMax/100)*100) ' RPM.']);
disp(['One motor uses ' num2str(round(comboChosen.powerHover)) ' W of electrical power at hover and ' num2str(round(comboChosen.powerMax)) ' W of electrical power at WOT.']);
disp(['The drive should be controlled by a ' num2str(ceil(comboChosen.currentRating)) ' A ESC per motor.']);
disp(['The whole system should be powered by ' num2str(BattCellNo) 'S ' num2str(ceil(minBattRating)) 'C LiPo batteries of '...
    num2str(round(BattCapacity_Ah*1000, -3)) ' mAh.']);
disp('---------');
disp(['Hovering flight requires ' num2str(round(RotorNo*comboChosen.powerHover)) ' W of mechanical power (' 'TORQUE'...
    ' Nm at ' num2str(round(comboChosen.speedHover/100)*100) ' RPM) to achieve ' num2str(round(comboChosen.thrustHover*RotorNo)) ' gf of total thrust.']);
disp(['WOT flight requires ' num2str(round(RotorNo*comboChosen.powerMax)) ' W of mechanical power (' 'TORQUE'...
    ' Nm at ' num2str(round(comboChosen.speedMax/100)*100) ' RPM) to achieve ' num2str(round(comboChosen.thrustMax*RotorNo)) ' gf of total thrust.']);
disp(['This configuration should achieve around ' num2str(round(time_hover(end)*60)) ' min of hover and around ' num2str(round(time_max(end)*60)) ' min of flight at WOT.']);

% plot_propPerf; % plot propeller performance & battery simulation results 
% plot_motorPerf; % plot motor performance % TODO FIXME

function filteredComboList = filterComboList(comboList, PDmin, PDmax, Mmax)
    filteredComboList = [];
    for i = 1:size(comboList,2)
        if comboList(i).propDiameter <= PDmax && comboList(i).propDiameter...
                >= PDmin && comboList(i).massCombined <= 2*Mmax
            filteredComboList = [filteredComboList, comboList(i)];
        end
    end
end