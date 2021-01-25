% iteratePayloadAndBattery.m

function output = iteratePayload(params, payload_info)

payload_min = payload_info(1);
payload_step = payload_info(2);
payload_max = payload_info(3);

i = 1;
hover_list = [];
max_list = [];
mass_list = [];
payload_list = [];
for payload = payload_min:payload_step:payload_max
    mass_Payload = payload;
    params.mass_NoDrive_Est = mass_Payload + params.mass_NoDrive_NoPayload_Est;
    data{i} = multirotorSizingAlgorithm(params);
    hover_list = [hover_list, data{i}{2}];
    max_list = [max_list, data{i}{3}];
    mass_list = [mass_list, data{i}{4}/1000];
    payload_list = [payload_list, payload];
%     [num2str(wh),' ',data{j}{1}.motorName,' ',data{j}{1}.propName]
    i = i + 1;
end
    
output = data;

figure(1); clf; hold on
title(['Flight with ' num2str(params.Wh) 'Wh Battery'])
plot(payload_list, hover_list)
plot(payload_list, max_list)
xlabel('Payload Mass (g)')
ylabel('Flight Time (min)')
yyaxis right;
plot(payload_list, mass_list)
ylabel('Total Mass (kg)')
legend({'Hover','WOT','Take-Off Mass'},'Location','Northeast')
    
end