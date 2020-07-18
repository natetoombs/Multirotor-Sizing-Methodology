% main.m
%
% To determine an ideal system, finding the right battery size
% is crucial. This function solves for the best system while 
% increasing the battery size (in Watt Hours).

close all; clear, clc;
format compact; format shortG;

% Set Params
params = Parameters();
params.RotorNo = 8; % Number of Rotors
params.Coaxial = true; % Coaxial motors have 15% loss %TODO: Cite
params.useWheelbase = true; % Use wheelbase to determine max prop size;
                    % works with 4,6,8-rotor, and coaxial 8,12,16-rotor
params.Wheelbase = 650/25.4; % in; Diagonal from motor to motor %TODO: include math n paper
params.useOverlap = false; % Allow props to overlap; %TODO Add Functionality
params.Overlap = 0.15; % percent; 15% is likely the max safe overlap %TODO cite paper
params.PropDiameter_Min = 8; % in; Smallest size that will be searched
params.PropDiameter_Max = 22.5; % in % Largest size; ignored if useWheelbase
params.DisplayResults = true; % Print results at the end of the function
params.SelectBattCellNo = false; % If you want to specify the cell #
params.BattCellNo_Desired = 0;
params.ThrustWeightRatio = 1.8;
                    % 2 - minimum
                    % 3 - payload transport
                    % 4 - surveillence
                    % 5+ - aerobatics / hi-speed video
                    % 7+ - racing
params.OptimisationGoal = 'hover';
                    % hover - best specific thrust (g/W) at hover
                    % max - best specific thrust (g/W) at 100% throttle
                    % utilisation - maximum usable power range of propeller

% Determine Mass before Motor, Propeller, & Battery [g]
mass_Frame = 475;
mass_Computer = 300; % Intel NUC
mass_FC = 20;
mass_Sensors = 300 + 10; % Camera, Sonar
mass_Payload = 4500;
mass_Power_System = 68 + 12 + 100; % Boost Converter, UBEC, cables
mass_Other = 100;
mass_ESC_Est = 32; % 30A 

% Estimate Motor & Propeller Mass; algorithm will search for combinations
% up to 200% their mass [g]
mass_Motor_Est = 100;
mass_Propeller_Est = 40;

params.mass_NoDrive_Est = mass_Frame + mass_FC + mass_Sensors + mass_Payload + mass_Other + mass_ESC_Est*params.RotorNo;
params.mass_Combo_Est = mass_Motor_Est + mass_Propeller_Est;

params.Wh = 360;

data = multirotorSizingAlgorithm(params);