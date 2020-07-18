% Load curves from combo lists
% output = Data array (see Data.m)

function output = loadSpecCurves(combo)
    sheet = combo.motorName(1:2);
    list = readtable('ComboList&Data.xlsx','Sheet',sheet);
    
    add = 6; %TODO: This means 7 lines of specs per combo

    counter = 1;
    for iRow = 1:add+1:size(list,1)
        if isequal(list{iRow,'Motor'}{1},combo.motorName)
            if isequal(list{iRow,'Propeller'}{1},combo.propName)
                data = Data();
                data.Voltage = list{iRow,'Voltage'};
                data.Power = list{iRow:iRow+add,'Power'};
                data.Thrust = list{iRow:iRow+add,'Thrust'};
                data.RPM = list{iRow:iRow+add,'RPM'};
                rows = add+1;
                ii = 1;
                while ii <= rows
                    if ~isfinite(data.Power(ii))
                        data.Power(ii) = [];
                        data.Thrust(ii) = [];
                        data.RPM(ii) = [];
                        ii = ii-1;
                        rows = rows-1;
                    end
                    ii = ii + 1;
                end
                output(counter) = data;
                counter = counter+1;
            end
        end
    end
    if counter == 1
        output = 0;
    end
end
    