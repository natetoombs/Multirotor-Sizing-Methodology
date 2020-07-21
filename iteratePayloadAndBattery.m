% iteratePayloadAndBattery.m

function output = iteratePayloadAndBattery(params, payload_info, battery_info)

payload_min = payload_info(1);
payload_step = payload_info(2);
payload_max = payload_info(3);

battery_min = battery_info(1);
battery_step = battery_info(2);
battery_max = battery_info(3);

fig_num = 1;
j = 1;
for payload = payload_min:payload_step:payload_max
    mass_Payload = payload;
    params.mass_NoDrive_Est = mass_Payload + params.mass_NoDrive_NoPayload_Est;
    i = 1;
    wh_list = [];
    hover_list = [];
    max_list = [];
    mass_list = [];
    for wh = battery_min:battery_step:battery_max
        params.Wh = wh; % Set the number of Watt Hours for the battery
        data{i,j} = multirotorSizingAlgorithm(params);
        wh_list = [wh_list, wh];
        hover_list = [hover_list, data{i,j}{2}];
        max_list = [max_list, data{i,j}{3}];
        mass_list = [mass_list, data{i,j}{4}/1000];
    %     [num2str(wh),' ',data{j}{1}.motorName,' ',data{j}{1}.propName]
        i = i + 1;
    end

    output = data;
    
    figure(fig_num); clf; hold on
    title(['Flight with ' num2str(payload) 'g Payload'])
    plot(wh_list, hover_list)
    plot(wh_list, max_list)
    xlabel('Battery Capacity (Wh)')
    ylabel('Flight Time (min)')
    yyaxis right;
    plot(wh_list, mass_list)
    ylabel('Mass (kg)')
    legend({'Hover','WOT','Take-Off Mass'},'Location','Northwest')
    
    fig_num = fig_num + 1;
    j = j + 1;
end
end