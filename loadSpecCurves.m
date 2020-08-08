% Load curves from combo lists for a given combo
% If there are multiple instances of the combo at different
% voltages, the function will return a data array for each
% voltage.
%
% There need to be add+1 rows of data for each instance of each combo, see
% line 19.
%
% Some of the data don't include stats at 0 power/rpm/thrust. Because the
% data are being interpolated, this function adds a row of 0's if there
% isn't already one.
%
% output = Data array (see Data.m)

function output = loadSpecCurves(combo)
    sheet = combo.motorName(1:2);
    list = readtable('ComboList&Data.xlsx','Sheet',sheet);
    
    add = 6; % THere must be 6+1= 7 lines of data for each combo instance

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
                    if ~isfinite(data.Power(ii)) % Ignore empty rows
                        data.Power(ii) = [];
                        data.Thrust(ii) = [];
                        data.RPM(ii) = [];
                        ii = ii-1;
                        rows = rows-1;
                    end
                    ii = ii + 1;
                end
                % If there isn't a row of 0's, add one
                if isempty(find(data.RPM == 0,1))
                    data.Power = [0; data.Power];
                    data.Thrust = [0; data.Thrust];
                    data.RPM = [0; data.RPM];
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
    