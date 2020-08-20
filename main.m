% Multirotor Sizing Methodology with Flight Time Estimation
%
% Original code created by M. Biczyski, R. Sehab, G.Krebs, J.F. Whidborne,
% P. Luk
%
% Modified by Nathan Toombs
% Changed all spellings of 'Optimisation' to 'Optimization', among other
% improvements.
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
params = Parameters();
params.RotorNo = 8; % Number of Rotors
params.Coaxial = true; % Coaxial motors can have about 15% loss
params.useWheelbase = false; % Use wheelbase to determine max prop size;
                    % works with 4,6,8-rotor, and coaxial 8,12,16-rotor
params.Wheelbase = 1700/25.41; % in; Diagonal from motor to motor
params.useOverlap = true; % Allow props to overlap;
params.Overlap = 0.1; % percent; 15% is max recommended, and 39% will have the props overlap adjacent motors
params.PropDiameter_Min = 20; % in; Smallest size that will be searched
params.PropDiameter_Max = 16.971; % in % Largest size; IGNORED if useWheelbase
params.DisplayResults = true; % Print results at the end of the function
params.SelectBattCellNo = false; % If you want to specify the cell
params.BattCellNo_Desired = 0; % Must be even; IGNORED if SelectBattCellNo == false
params.ThrustWeightRatio = 1.65;
                    % 1.65 - hover throttle = 60% thrust; poor wind flight
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
mass_Frame = 6500;
mass_Computer = 300; % Intel NUC
mass_FC = 20;
mass_Sensors = 500 + 10; % Camera, Sonar
mass_Payload = 5000; % 22500g = 50lbs
mass_Power_System = 68 + 12 + 100; % Boost Converter, UBEC, cables
mass_Other = 200; % Cables, other things
mass_ESC_Est = 32; % 30A 

% Estimate Motor & Propeller Mass; algorithm will search for combinations
% up to 200% their mass [g]
mass_Motor_Est = 1300;
mass_Propeller_Est = 200;

params.mass_NoDrive_NoPayload_Est = mass_Frame + mass_FC + mass_Sensors + mass_Power_System + mass_Other + mass_ESC_Est*params.RotorNo;
params.mass_NoDrive_Est = mass_Frame + mass_FC + mass_Sensors + mass_Payload + mass_Power_System + mass_Other + mass_ESC_Est*params.RotorNo;
params.mass_Combo_Est = mass_Motor_Est + mass_Propeller_Est;

% Define Battery Power
params.Wh = 2000;

% Choose Optimization Method
method = 'singleRun';
        % 'singleRun' -- Define the battery and payload, run once
        % 'iterateBattery' -- Define a battery range and iterate
        % 'iteratePayloadAndBattery' -- Define ranges and iterate
        
if isequal(method,'singleRun')
    % Uses above defined payload, Wh
    data = multirotorSizingAlgorithm(params);
elseif isequal(method,'iterateBattery')
    % Uses above defined payload
    battery_min = 3000;
    battery_step = 250;
    battery_max = 8000;
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