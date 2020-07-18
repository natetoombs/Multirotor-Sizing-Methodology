%% ------------------------------------------------------------------------
% Multirotor Sizing Methodology
% with Flight Time Estimation
%
% M. Biczyski, R. Sehab, G.Krebs, J.F. Whidborne, P. Luk
%
% heavy_lift.m - copy of main.m
% Revisions made include:
%   - Coaxial Motor Option
%   - Use multiple batteries
%   - Propeller and Motor Classes
%% ------------------------------------------------------------------------

close all; clear; clc;
format compact; format shortG;

RPM2RAD = 2*pi/60;
RAD2RPM = 60/2/pi;

%% User parameters
RotorNo = 8; % Number of rotors
Coaxial = false;
OptimisationGoal = 'hover'; % selection criteria
                    % hover - best specific thrust (g/W) at hover
                    % max - best specific thrust (g/W) at 100% throttle
                    % utilisation - maximum usable power range of propeller
ThrustWeightRatio = 2; % estimator for maximum performance
                    % 2 - minimum
                    % 3 - payload transport
                    % 4 - surveillence
                    % 5+ - aerobatics / hi-speed video
                    % 7+ - racing
PropDiameter_Min = 0; % inch, min. propeller diameter
PropDiameter_Max = 10; % inch, max. propeller diameter
SafetyFactor = 1.1; % [1-2], arbitrary safety parameter
ParallelBattNo = 4; % # of batteries in ||; if there are 4 batteries, but two pairs in series, then = 2
BattCellNo = 12; %S 1P, battery cell count
BattCellVoltage = 3.7; % V per cell, battery cell voltage
BattCapacityEa = 30000; % mAh, capacity per battery in ||; if two batteries are in series, use mAh of one of the two
TotalBattCapacity = ParallelBattNo*BattCapacityEa; % mAh, total battery capacity
BattPeukertConstant = 1.3; % for LiPo, Peukert's constant for selected type of battery
BattVoltageSagConstant = 0.5/0.8*BattCellNo; % 0.5V decrease per cell in resting volatage for 80% DoD
BattHourRating = 1; % h

%% Mass data [g]
mass_Frame = 15000; % Estimate for large frame = 3000
mass_FC = 0; % Ignore
mass_FC_GPS = 0; % Ignore
mass_FC_CurrentSensor = 0; % Ignore
mass_Receiver = 0; % Ignore
mass_Motor_Max = 800; % max motor mass/ea
mass_ESC_Est = 0; % Ignore
mass_Propeller_Max = 110; % max prop mass %TODO
mass_Payload = 23000; % 20 lbs = 9000
BatteryNo = 2;
mass_Battery_Each = 14500; % Tattu
mass_Battery_Total = mass_Battery_Each*BatteryNo;
mass_Other_Est = 0; % Ignore

mass_NoDrive_Est = mass_Frame + mass_FC + mass_FC_GPS + mass_FC_CurrentSensor + mass_Receiver + mass_Payload + mass_Other_Est;
mass_Total_Est = mass_NoDrive_Est + RotorNo*(mass_Motor_Max + mass_ESC_Est + mass_Propeller_Max) + mass_Battery_Total;
%% Propeller Set and Performance
propList = load_propList();
propList_considered = [];

% Filter by size, data availability:
for ii = 1:size(propList,2)
    if propList(ii).diameter >= PropDiameter_Min && propList(ii).diameter <= PropDiameter_Max
        propList_considered = [propList_considered, propList(ii)];
    end
end

consideredNo = size(propList_considered,2); % size of filtered set

if consideredNo < 1
    error('ERROR! No matching propeller found!');
end

    propPerf = {};
for ii = 1:consideredNo
    % TRUE/FALSE for plot
    propPerf(ii) = {load_propPerf(propList_considered(ii),false)}; % loading propeller static performance data
end

    % Calculate operating points
if Coaxial
    thrustHover_Est = 1/0.85*mass_Total_Est/RotorNo; % calculate thrust/motor required for hover
else
    thrustHover_Est = mass_Total_Est/RotorNo; % calculate thrust/motor required for hover
end
thrustMax_Est = thrustHover_Est*ThrustWeightRatio; % calculate estimated thrust/motor at WOT
for ii = 1:consideredNo
    speedHover = interp1(propPerf{ii}(:,2), propPerf{ii}(:,1), thrustHover_Est, 'linear', 'extrap'); % obtaining propeller speed at hover from required thrust for hover, Eq. (11)
    speedMax = interp1(propPerf{ii}(:,2), propPerf{ii}(:,1), thrustMax_Est, 'linear', 'extrap'); % obtaining propeller speed at WOT from estimated thrust at WOT , Eq. (11)
    speedLimit = propList_considered(ii).rpm_max; % obtaining propeller's limiting speed specified by the manufacturer
    torqueHover = interp1(propPerf{ii}(:,1), propPerf{ii}(:,4), speedHover, 'linear', 'extrap'); % Eq. (12)
    torqueMax = interp1(propPerf{ii}(:,1), propPerf{ii}(:,4), speedMax, 'linear', 'extrap');
    torqueLimit = interp1(propPerf{ii}(:,1), propPerf{ii}(:,4), speedLimit, 'linear', 'extrap');
    thrustLimit = interp1(propPerf{ii}(:,1), propPerf{ii}(:,2), speedLimit, 'linear', 'extrap');
    powerHover = interp1(propPerf{ii}(:,1), propPerf{ii}(:,3), speedHover, 'linear', 'extrap'); % Eq. (13)
    powerMax = interp1(propPerf{ii}(:,1), propPerf{ii}(:,3), speedMax, 'linear', 'extrap');
    powerLimit = interp1(propPerf{ii}(:,1), propPerf{ii}(:,3), speedLimit, 'linear', 'extrap');
    % eq. (8), (9)
    propList_considered(ii).OPhover = [speedHover thrustHover_Est torqueHover powerHover]; % obtaining hover operating point
    propList_considered(ii).OPmax = [speedMax thrustMax_Est torqueMax powerMax]; % obtaining WOT operating point
    propList_considered(ii).OPlimit = [speedLimit thrustLimit torqueLimit powerLimit]; % obtaining speed limit operating point
end

%% Select propeller
for ii = 1:consideredNo
    switch OptimisationGoal % selection of approperiate criteria based on user's choice
        case 'hover'
            selectionCriterion(ii,1) = propList_considered(ii).OPhover(1)*2*pi/60*propList_considered(ii).OPhover(3); % speed*torque (Power) at hover
            selectionCriterion(ii,2) = propList_considered(ii).OPhover(4);
        case 'max'
            selectionCriterion(ii,1) = (propList_considered.OPmax(1)*2*pi/60)*propList_considered.OPmax(3);
            selectionCriterion(ii,2) = propList_considered.OPmax(4); % power at WOT
        case 'utilisation'
            selectionCriterion(ii,1) = (propList_considered.OPlimit(1)*2*pi/60)*propList_considered.OPlimit(3) - (propList_considered.OPmax(1)*2*pi/60)*propList_considered.OPmax(3);
            selectionCriterion(ii,2) = propList_considered.OPlimit(4) - propList_considered.OPmax(4); % best usage of propeller's speed range
        otherwise
            error('ERROR! Wrong optimisation criteria!');
    end
end

methodError(:,1) = abs(selectionCriterion(:,2) - selectionCriterion(:,1)); % absolute error between power and the product of speed and torque due to interpolation
methodError(:,2) = abs(selectionCriterion(:,2) - selectionCriterion(:,1))./abs(selectionCriterion(:,2)); % relative interpolation error
for ii = 1:consideredNo
    if propList_considered(ii).OPlimit(1) < propList_considered(ii).OPmax(1) || isnan(propList_considered(ii).OPmax(1))
        selectionCriterion(ii,:) = inf; % rejecting propellers with numerical errors and with WOT speed over limit speed
    end
end

[~, temp_propChosen_pos] = min(mean(selectionCriterion,2)); % selection of best propeller for the application

propChosen = propList_considered(temp_propChosen_pos);

if selectionCriterion(temp_propChosen_pos,2) == inf
    error('ERROR! No matching propeller found!');
end

%% Load and filter motor data
 % motorList = load_motorListx(voltage, prop_speedMax, prop_torqueMax, prop_speedHover, prop_torqueHover, spec_mass)
motorList = load_motorListx(BattCellNo*BattCellVoltage, propChosen.OPmax(1), propChosen.OPmax(3),...
    propChosen.OPhover(1), propChosen.OPhover(3)*SafetyFactor,...
    mass_Motor_Max, brand); % loading motor set with operating points

    if size(motorList,2) < 1
    error('ERROR! No matching motor found!');
    end
% Select motor
switch OptimisationGoal % selection of approperiate criteria based on user's choice, Eq. (29)
    case 'hover'
        [~, temp_motorChosen_pos] = min([motorList(:).Phover]); % power at hover
    case 'max'
        [~, temp_motorChosen_pos] = min([motorList(:).Pmax]); % power at WOT
    case 'utilisation'
        [~, temp_motorChosen_pos] = min(abs([motorList{:,3}]-[motorList{:,7}])); %TODO  % best usage of motor's current range
    otherwise
        error('ERROR! Wrong optimisation criteria!');
end

motorChosen = motorList(temp_motorChosen_pos); % selection of best motor for the application

%% Determine drive specification
% propSpecification = name, diameter (in), pitch (in)
% motorSpecification = name, speedMax (RPM), torqueMax (Nm), powerMax (W), powerMaxEl (W), EfficiencyMax(%), voltageNominal (V)
% motorSpec = name, Kv, speedMax, 
% escSpecification = currentMax (A)
% baterrySpecification = NoCells, C-rating, minCapacity (mAh)

maxSpeed = propChosen.OPmax(1);
maxTorque = propChosen.OPmax(3)*SafetyFactor;
maxPower = propChosen.OPmax(4)*SafetyFactor;
escSpecification = motorChosen.Imax;

BattCapacity_Ah = TotalBattCapacity/1000;
minBattRating = escSpecification*RotorNo*SafetyFactor/BattCapacity_Ah; % calculate min. battery C-rating required to supply enough current to motors
batterySpecification = [BattCellNo, minBattRating, TotalBattCapacity];

mass_Propeller = propChosen.mass;
mass_Motor = motorChosen.mass;
mass_ESC = mass_ESC_Est;
mass_Total = mass_NoDrive_Est + RotorNo*(mass_Motor + mass_ESC + mass_Propeller) + mass_Battery_Total; % recalculate total mass of multirotor using real component weights

%% Calculate initial battery state
voltage_hover(1) = (BattCellNo*(BattCellVoltage+0.5)); % 4.2 V per cell times number of cells
voltage_max(1) = (BattCellNo*(BattCellVoltage+0.5));
current_hover(1) = motorChosen.Ihover*RotorNo; % calculate total current at hover
current_max(1) = motorChosen.Imax*RotorNo; % calculate total current at WOT
capacity_hover(1) = (current_hover(1)^(1-BattPeukertConstant))*(BattHourRating^(1-BattPeukertConstant))*(BattCapacity_Ah^BattPeukertConstant); % from modified Peukert's equation calculate available capacity at hover
capacity_max(1) = (current_max(1)^(1-BattPeukertConstant))*(BattHourRating^(1-BattPeukertConstant))*(BattCapacity_Ah^BattPeukertConstant); % from modified Peukert's equation calculate available capacity at WOT

%% Calculate next flight iterations
timeStep = 1/60/60; % set timestep as 1 s
ii = 1;
while voltage_hover(ii) > BattCellVoltage*BattCellNo && ii*timeStep < 2
    voltage_hover(ii+1) = voltage_hover(1) - (BattVoltageSagConstant/capacity_hover(1))*(capacity_hover(1) - capacity_hover(ii)); % calculate instantaneus voltage including voltage sag
    current_hover(ii+1) = motorChosen.Phover*RotorNo/voltage_hover(ii+1); % calculate instantaneus current based on required power for hover
    capacity_hover(ii+1) = (current_hover(ii+1)^(1-BattPeukertConstant))*(BattHourRating^(1-BattPeukertConstant))*(BattCapacity_Ah^BattPeukertConstant) - sum(current_hover(2:end)*timeStep); % calculate remaining available capacity according to Paeukert's effect
    ii = ii+1;
end
time_hover = (0:ii-1)*timeStep; % calculate time spent in hover

ii = 1;
while voltage_max(ii) > BattCellVoltage*BattCellNo && ii*timeStep < 2
    voltage_max(ii+1) = voltage_max(1) - (BattVoltageSagConstant/capacity_max(1))*(capacity_max(1) - capacity_max(ii)); % calculate instantaneus voltage including voltage sag
    current_max(ii+1) = motorChosen.Pmax*RotorNo/voltage_max(ii+1); % calculate instantaneus current based on estimated power at WOT
    capacity_max(ii+1) = (current_max(ii+1)^(1-BattPeukertConstant))*(BattHourRating^(1-BattPeukertConstant))*(BattCapacity_Ah^BattPeukertConstant) - sum(current_max(2:end)*timeStep); % calculate remaining available capacity according to Paeukert's effect
    ii = ii+1;
end
time_max = (0:ii-1)*timeStep; % calculate time spent at WOT

%% Display results and plot characteristics
disp(['For a ' num2str(RotorNo) '-rotor drone with estimated AUM of ' num2str(round(mass_Total_Est)) ' g (calculated TOM of ' num2str(round(mass_Total)) ' g):']);

switch OptimisationGoal
    case 'hover'
        textOptimisation = ['the highest specific thrust of ' num2str(round(propChosen.OPhover(2)/motorChosen.Phover*100)/100)  ' gf/W per motor at hover.'];
    case 'max'
        textOptimisation = ['the highest specific thrust of ' num2str(round(propChosen.OPmax(2)/motorChosen.Pmax*100)/100)  ' gf/W per motor at WOT.'];
    case 'utilisation'
        textOptimisation = 'maximum usable power range of propeller';
    otherwise
        error('ERROR! Wrong optimisation criteria!');
end
        
disp(['The ' propChosen.brand ' ' propChosen.name ' propeller should be chosen for ' textOptimisation]);
disp(['The ' motorChosen.brand ' ' motorChosen.name ' (' num2str(round(motorChosen.KV/10)*10) ' KV) motor should be selected with '...
    num2str(round(maxTorque*100)/100) ' Nm torque at maximum speed of ' num2str(round(maxSpeed/100)*100) ' RPM.']);
disp(['One motor uses ' num2str(round(motorChosen.Phover)) ' W of electrical power at hover and ' num2str(round(motorChosen.Pmax)) ' W of electrical power at WOT.']);
disp(['The drive should be controlled by a ' num2str(ceil(escSpecification)) ' A ESC per motor.']);
disp(['The whole system should be powered by ' num2str(ParallelBattNo) ' ' num2str(batterySpecification(1)) 'S ' num2str(ceil(batterySpecification(2))) 'C LiPo batteries of '...
    num2str(batterySpecification(3)) ' mAh.']);
disp('---------');
disp(['Hovering flight requires ' num2str(round(RotorNo*propChosen.OPhover(4))) ' W of mechanical power (' num2str(round(propChosen.OPhover(3)*100)/100)...
    ' Nm at ' num2str(round(propChosen.OPhover(1)/100)*100) ' RPM) to achieve ' num2str(round(propChosen.OPhover(2)*RotorNo)) ' gf of total thrust.']);
disp(['WOT flight requires ' num2str(round(RotorNo*propChosen.OPmax(4))) ' W of mechanical power (' num2str(round(propChosen.OPmax(3)*100)/100)...
    ' Nm at ' num2str(round(propChosen.OPmax(1)/100)*100) ' RPM) to achieve ' num2str(round(propChosen.OPmax(2)*RotorNo)) ' gf of total thrust.']);
disp(['This configuration should achieve around ' num2str(round(time_hover(end)*60)) ' min of hover and around ' num2str(round(time_max(end)*60)) ' min of flight at WOT.']);

% plot_propPerf; % plot propeller performance & battery simulation results 
% plot_motorPerf; % plot motor performance % TODO FIXME
