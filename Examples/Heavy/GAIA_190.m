% main.m
% http://www.omgfly.com/gaia-190mpheavy-lift-droneframe-version-p-3785.html
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
params.Wheelbase = 1900/25.41; % in; Diagonal from motor to motor %TODO: include math n paper
params.useOverlap = false; % Allow props to overlap;
params.Overlap = 0.15; % percent; 15% is likely the max safe overlap, and .39% will have the props overlap adjacent motors %TODO cite paper
params.PropDiameter_Min = 17; % in; Smallest size that will be searched
params.PropDiameter_Max = 28; % in % Largest size; IGNORED if useWheelbase
params.DisplayResults = true; % Print results at the end of the function
params.SelectBattCellNo = false; % If you want to specify the cell #
params.BattCellNo_Desired = 0; % IGNORED if SelectBattCellNo == false
params.ThrustWeightRatio = 1.65;
                    % 1.65 - hover throttle at 60% thrust
                    % 2 - minimum recommended; hover throttle = 50% thrust
                    % 3 - payload transport
                    % 4 - surveillence
                    % 5+ - aerobatics / hi-speed video
                    % 7+ - racing
params.OptimizationGoal = 'hover';
                    % hover - best specific thrust (g/W) at hover
                    % max - best specific thrust (g/W) at 100% throttle
                    % utilization - maximum usable power range of propeller

% Determine Mass before Motor, Propeller, & Battery [g]
mass_Frame = 6000; %5.1kg frame + 2.9kg landing gear? Make 0.9kg landing gear.
mass_Computer = 300; % Intel NUC
mass_FC = 20;
mass_Sensors = 500 + 10; % Camera, Sonar
mass_Payload = 22500; % 22500g = 50lbs
mass_Power_System = 68 + 12 + 100; % Boost Converter, UBEC, cables
mass_Other = 200; % Cables, other things
mass_ESC_Est = 32; % 30A 

% Estimate Motor & Propeller Mass; algorithm will search for combinations
% up to 200% their mass [g]
mass_Motor_Est = 800;
mass_Propeller_Est = 100;

params.mass_NoDrive_NoPayload_Est = mass_Frame + mass_FC + mass_Sensors + mass_Power_System + mass_Other + mass_ESC_Est*params.RotorNo;
params.mass_NoDrive_Est = mass_Frame + mass_FC + mass_Sensors + mass_Payload + mass_Power_System + mass_Other + mass_ESC_Est*params.RotorNo;
params.mass_Combo_Est = mass_Motor_Est + mass_Propeller_Est;

% Define Battery Power
params.Wh = 7000;

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
    battery_min = 3500;
    battery_step = 500;
    battery_max = 7000;
    battery_info = [battery_min, battery_step, battery_max];
    data = iterateBattery(params, battery_info);
elseif isequal(method,'iteratePayloadAndBattery')
    payload_min = 11500;
    payload_step = 5000;
    payload_max = 22500;
    payload_info = [payload_min, payload_step, payload_max];
    battery_min = 1200;
    battery_step = 20;
    battery_max = 2000;
    battery_info = [battery_min, battery_step, battery_max];
    data = iteratePayloadAndBattery(params, payload_info, battery_info);
else
    disp(['Error: ' method ' is not a valid method.']);
end