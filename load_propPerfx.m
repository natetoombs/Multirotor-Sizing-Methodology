

% output = [rpm, thrust, power, torque];
function output = load_propPerfx(prop)
    fileID = fopen('proptests.txt', 'rt');

    temp1 = fgetl(fileID);
    while ~strcmp(sscanf(temp1, '%s'), prop.name)
        temp1 = fgetl(fileID);
    end
    
    if isequal(prop.brand, 'XOAR')
        currentLine = sscanf(fgetl(fileID), '%f %f %f %f %f');
        testData = [];
        while ~isempty(currentLine) % read next lines of data until blank space or end of file
            testData(end+1, :) = currentLine;
            temp2 = fgetl(fileID);
            if temp2 == -1
                temp2 = '';
            end
            currentLine = sscanf(temp2, '%f %f %f %f %f');
        end
        fclose(fileID); % close data file

        thrust = testData(:,2);
        torque = testData(:,3);
        rpm = testData(:,6);
        power = testData(:,4).*testData(:,5); % V*A
    elseif isequal(prop.brand, 'T-MOTOR')
        currentLine = sscanf(fgetl(fileID), '%f %f %f %f');
        testData = [];
        while ~isempty(currentLine) % read next lines of data until blank space or end of file
            testData(end+1, :) = currentLine;
            temp2 = fgetl(fileID);
            if temp2 == -1
                temp2 = '';
            end
            currentLine = sscanf(temp2, '%f %f %f %f');
        end
        fclose(fileID); % close data file

        thrust = testData(:,4);
        torque = testData(:,3);
        rpm = testData(:,2);
        power = testData(:,1);
    elseif isequal(prop.brand, 'KDE')
        currentLine = sscanf(fgetl(fileID), '%f %f %f %f');
        testData = [];
        while ~isempty(currentLine) % read next lines of data until blank space or end of file
            testData(end+1, :) = currentLine;
            temp2 = fgetl(fileID);
            if temp2 == -1
                temp2 = '';
            end
            currentLine = sscanf(temp2, '%f %f %f %f');
        end
        fclose(fileID); % close data file

        thrust = testData(:,2);
        torque = testData(:,4);
        rpm = testData(:,3);
        power = testData(:,1);
    end
    
    output = [rpm, thrust, power, torque];
end