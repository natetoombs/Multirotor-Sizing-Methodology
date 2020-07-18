
% output = name, dia, pitch, maxRPM, data?
function output = load_propListx(brand)
    [~, ~, raw] = xlsread('proplist.xlsx');
    
    jj = 1;
    for ii = 2:size(raw,1) % skip first line
        p = Propeller();
        [p.brand, p.name, p.diameter, p.pitch, p.mass, p.rpm_max, p.data] = deal(raw{ii,1:7});
        p.rpm_max = str2double(erase(p.rpm_max,'rpm')); % Remove 'rpm'
        
        if isequal(p.brand, brand)
            propList(jj) = p;
            jj = jj + 1;
        end
    end
    
    output = propList;
end