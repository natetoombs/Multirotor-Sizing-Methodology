% Multirotor Sizing Methodology with Flight Time Estimation
%
% Original code created by M. Biczyski, R. Sehab, G.Krebs, J.F. Whidborne,
% P. Luk
%
% Modified by Nathan Toombs
% Changed all spellings of 'Optimisation' to 'Optimization', among other
% modifications.
%
% main.m - After setting parameters, calls the multirotorSizingAlgorithm.
% Change the optimization method to iterate between battery and payload
% sizes. 
%
% To determine an ideal system, finding the right battery size
% is crucial. This function solves for the best system while 
% increasing the battery size (in Watt Hours) when the optimization method 
% is 'iterateBattery' or 'iteratePayloadAndBattery'.
%
% More information on the configurations is found in the 'data' cell array,
% which includes the combination information, the hover time in minutes,
% the WOT time in minutes, the total mass, and the battery capacity (Wh).

close all; clear, clc;
format compact; format shortG;

% Set Params
RotorNo = 4; % Number of Rotors
Coaxial = false; % Coaxial motors can have about 15% loss

% Set total mass
total_Mass = 2000; % g
ThrustWeightRatio = 1.85; % Figure out what you want with this
SafetyFactor = 1.0;
OptimizationGoal = 'hover';

% Define Battery Power
Wh = 2000;
BattCellNo = 4; % Corresponds to nominal voltage (3.7V per cell)
BattCapacity_Ah = 5.2; % Ah

% Test Data
start_Voltage = 16.7; % V
end_Voltage = 14.6; % V

flight_Time = 12.5; % minutes

combo = loadComboList(); % Set the combo as the only active in the list

%% Get Operating Points
if Coaxial
    thrustHover = 1/0.85*total_Mass/RotorNo; % calculate thrust/motor required for hover
else
    thrustHover = total_Mass/RotorNo; % calculate thrust/motor required for hover
end
thrustMax = thrustHover*ThrustWeightRatio;
combo = getOperatingPoints(combo, thrustHover, thrustMax, BattCellNo);

%% Determine battery specification, total mass
BattCellVoltage = 3.7; % V per cell
BattVoltageSagConstant = 0.5/0.8*BattCellNo;
minBattRating = combo.powerMax/combo.voltage*RotorNo*SafetyFactor/BattCapacity_Ah;
BattPeukertConstant = 1.3; % n; for LiPo, Peukert's constant for selected type of battery
BattHourRating = 1; % h

 %% Calculate initial battery state
voltage_hover(1) = start_Voltage;
voltage_max(1) = start_Voltage;
current_hover(1) = combo.powerHover/voltage_hover(1)*RotorNo; % calculate total current at hover
current_max(1) = combo.powerMax/voltage_max(1)*RotorNo; % calculate total current at WOT
capacity_hover(1) = (current_hover(1)^(1-BattPeukertConstant))*(BattHourRating^(1-BattPeukertConstant))*(BattCapacity_Ah^BattPeukertConstant); % from modified Peukert's equation calculate available capacity at hover
capacity_max(1) = (current_max(1)^(1-BattPeukertConstant))*(BattHourRating^(1-BattPeukertConstant))*(BattCapacity_Ah^BattPeukertConstant); % from modified Peukert's equation calculate available capacity at WOT

%% Calculate next flight iterations
timeStep = 1/60/60; % set timestep as 1 s
ii = 1;
while voltage_hover(ii) > end_Voltage && ii*timeStep < 2
    voltage_hover(ii+1) = voltage_hover(1) - (BattVoltageSagConstant/capacity_hover(1))*(capacity_hover(1) - capacity_hover(ii)); % calculate instantaneus voltage including voltage sag
    current_hover(ii+1) = combo.powerHover*RotorNo/voltage_hover(ii+1); % calculate instantaneus current based on required power for hover
    capacity_hover(ii+1) = (current_hover(ii+1)^(1-BattPeukertConstant))*(BattHourRating^(1-BattPeukertConstant))*(BattCapacity_Ah^BattPeukertConstant) - sum(current_hover(2:end)*timeStep); % calculate remaining available capacity according to Paeukert's effect
    ii = ii+1;
end
time_hover = (0:ii-1)*timeStep; % calculate time spent in hover

ii = 1;
while voltage_max(ii) > BattCellVoltage*BattCellNo && ii*timeStep < 2
    voltage_max(ii+1) = voltage_max(1) - (BattVoltageSagConstant/capacity_max(1))*(capacity_max(1) - capacity_max(ii)); % calculate instantaneus voltage including voltage sag
    current_max(ii+1) = combo.powerMax*RotorNo/voltage_max(ii+1); % calculate instantaneus current based on estimated power at WOT
    capacity_max(ii+1) = (current_max(ii+1)^(1-BattPeukertConstant))*(BattHourRating^(1-BattPeukertConstant))*(BattCapacity_Ah^BattPeukertConstant) - sum(current_max(2:end)*timeStep); % calculate remaining available capacity according to Paeukert's effect
    ii = ii+1;
end
time_max = (0:ii-1)*timeStep; % calculate time spent at WOT

output = {combo, time_hover(end)*60, time_max(end)*60, total_Mass, Wh};


%% Display results and plot characteristics
disp(['For a ' num2str(RotorNo) '-rotor drone with TOM of ' num2str(round(total_Mass)) ' g:']);

switch OptimizationGoal
    case 'hover'
        textOptimization = ['the highest specific thrust of ' num2str(round(combo.thrustHover/combo.powerHover*100)/100)  ' gf/W per motor at hover.'];
    case 'max'
        textOptimization = ['the highest specific thrust of ' num2str(round(propChosen.OPmax(2)/powerChosen.powerMax*100)/100)  ' gf/W per motor at WOT.'];
    case 'utilization'
        textOptimization = 'maximum usable power range of propeller';
    otherwise
        error('ERROR! Wrong optimization criteria!');
end

disp(['The ' combo.propName ' propeller was chosen with ' textOptimization]);
disp(['The ' combo.motorName ' motor was selected.']);
disp(['One motor uses ' num2str(round(combo.powerHover)) ' W of electrical power at hover and ' num2str(round(combo.powerMax)) ' W of electrical power at WOT.']);
disp(['The whole system is be powered by ' num2str(BattCellNo) 'S LiPo batteries of '...
    num2str(BattCapacity_Ah*1000) ' mAh.']);
disp(['This configuration should achieve around ' num2str(round(time_hover(end)*60,1)) ' min of hover and around ' num2str(round(time_max(end)*60),1) ' min of flight at WOT.']);
disp('---------');