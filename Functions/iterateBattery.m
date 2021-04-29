% iterateBattery.m
%
% To determine an ideal system, finding the right battery size
% is crucial. This function solves for the best system while 
% increasing the battery size (in Watt Hours).
function output = iterateBattery(params, battery_info)

battery_min = battery_info(1);
battery_step = battery_info(2);
battery_max = battery_info(3);

i = 1;
wh_list = [];
hover_list = [];
max_list = [];
mass_list = [];
for wh = battery_min:battery_step:battery_max
    params.Wh = wh; % Set the number of Watt Hours for the battery
    data{i} = multirotorSizingAlgorithm(params);
    wh_list = [wh_list, wh];
    hover_list = [hover_list, data{i}{2}];
    max_list = [max_list, data{i}{3}];
    mass_list = [mass_list, data{i}{4}/1000];
%     [num2str(wh),' ',data{j}{1}.motorName,' ',data{j}{1}.propName]
    i = i + 1;
end

output = data;

figure(1); clf; hold on
title(['Flight Time with Increasing Battery Size'])
plot(wh_list, hover_list)
plot(wh_list, max_list)
xlabel('Battery Capacity (Wh)')
ylabel('Flight Time (min)')
yyaxis right;
plot(wh_list, mass_list)
ylabel('Mass (kg)')
legend({'Hover','WOT','Take-Off Mass'},'Location','Northwest')
end