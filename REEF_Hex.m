% main.m
%
% To determine an ideal system, finding the right battery size
% is crucial. This function solves for the best system while 
% increasing the battery size (in Watt Hours).

close all; clear, clc;
format compact; format shortG;

% Set Params
params = Parameters();
params.RotorNo = 6; % Number of Rotors
params.Coaxial = false; % Coaxial motors have 15% loss %TODO: Cite
params.useWheelbase = true; % Use wheelbase to determine max prop size;
                    % works with 4,6,8-rotor, and coaxial 8,12,16-rotor
params.Wheelbase = 690/25.41; % in; Diagonal from motor to motor %TODO: include math n paper
params.useOverlap = false; % Allow props to overlap; %TODO Add Functionality
params.Overlap = 0.15; % percent; 15% is likely the max safe overlap %TODO cite paper
params.PropDiameter_Min = 11; % in; Smallest size that will be searched
params.PropDiameter_Max = 16; % in % Largest size; IGNORED if useWheelbase
params.DisplayResults = true; % Print results at the end of the function
params.SelectBattCellNo = false; % If you want to specify the cell #
params.BattCellNo_Desired = 0; % IGNORED if SelectBattCellNo == false
params.ThrustWeightRatio = 1.65;
                    % 1.65 - hover throttle at 60%
                    % 2 - minimum recommended; hover throttle = 50% max
                    % 3 - payload transport
                    % 4 - surveillence
                    % 5+ - aerobatics / hi-speed video
                    % 7+ - racing
params.OptimisationGoal = 'hover';
                    % hover - best specific thrust (g/W) at hover
                    % max - best specific thrust (g/W) at 100% throttle
                    % utilisation - maximum usable power range of propeller

% Determine Mass before Motor, Propeller, & Battery [g]
mass_Frame = 600; % Tarot FY690S
mass_Computer = 300; % Intel NUC
mass_FC = 20;
mass_Sensors = 300 + 10; % Camera, Sonar
mass_Payload = 4500;
mass_Power_System = 68 + 12 + 100; % Boost Converter, UBEC, cables
mass_Other = 200; % Cables, other things
mass_ESC_Est = 32; % 30A 

% Estimate Motor & Propeller Mass; algorithm will search for combinations
% up to 200% their mass [g]
mass_Motor_Est = 150;
mass_Propeller_Est = 40;

params.mass_NoDrive_NoPayload_Est = mass_Frame + mass_FC + mass_Sensors + mass_Power_System + mass_Other + mass_ESC_Est*params.RotorNo;
params.mass_NoDrive_Est = mass_Frame + mass_FC + mass_Sensors + mass_Payload + mass_Power_System + mass_Other + mass_ESC_Est*params.RotorNo;
params.mass_Combo_Est = mass_Motor_Est + mass_Propeller_Est;

% Define Battery Power
params.Wh = 600;

% Choose Optimization Method
method = 'iterateBattery';
        % 'singleRun' -- Define the battery and payload, run once
        % 'iterateBattery' -- Define a battery range and iterate
        % 'iteratePayloadAndBattery' -- Define ranges and iterate
        
if isequal(method,'singleRun')
    % Uses above defined payload, Wh
    data = multirotorSizingAlgorithm(params);
elseif isequal(method,'iterateBattery')
    % Uses above defined payload
    battery_min = 450;
    battery_step = 50;
    battery_max = 650;
    battery_info = [battery_min, battery_step, battery_max];
    data = iterateBattery(params, battery_info);
elseif isequal(method,'iteratePayloadAndBattery')
    payload_min = 2250;
    payload_step = 250;
    payload_max = 4500;
    payload_info = [payload_min, payload_step, payload_max];
    battery_min = 300;
    battery_step = 50;
    battery_max = 600;
    battery_info = [battery_min, battery_step, battery_max];
    data = iteratePayloadAndBattery(params, payload_info, battery_info);
end