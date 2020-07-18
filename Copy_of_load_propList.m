%% ------------------------------------------------------------------------
% Multirotor Sizing Methodology
% with Flight Time Estimation
%
% M. Biczyski, R. Sehab, G.Krebs, J.F. Whidborne, P. Luk
%
% load_propList.m - implements function load_propList() that reads basic
% propeller information from the database; requires file 'WEBLIST.xlsx' 
% in 'PERFILES_WEB' folder and file 'PROP-DATA-FILE_202005.xlsx' from 
% APC Performance Database Summary
%% ------------------------------------------------------------------------

%%% WORK IN PROGRESS TODO TODO
% output = name, file, diameter (in), pitch (in), mass (g), speed_limit
function output = load_propList()
    [~, ~, everything] = xlsread('PERFILES_WEB/WEBLIST.xlsx'); % read from the data file

    fileList = [{} {}];
    for ii = 4:size(everything,1) % skip first 4 lines and save propeller names and respective filenames
        fileList(ii-3,:) = [everything(ii,3) everything(ii,1)];
%         p = Propeller();
%         p.name = everything{ii,3};
%         p.file = everything{ii,1};
%         
%         propList(ii-3) = p;
    end

    clear everything; % clear unused data

    [~, ~, everything] = xlsread('LISTS/PROP-DATA-FILE_202005.xlsx', 2); % read from the data file

    for ii = 1:size(fileList,1) % look for each propeller specified by name and save its parameters
        for jj = 2:size(everything,1)
            if startsWith(everything{jj, 1}, fileList{ii,1})
                fileList(ii, 3:5) = [str2num(everything{jj, 11})  % diameter
                                     everything(jj, 12)  % pitch
                                     everything(jj, 16)]; % mass
%                 propList(ii).diameter = str2num(everything{jj, 11});
%                 propList(ii).pitch = everything(jj, 12);
%                 propList(ii).mass = everything(jj, 16);
                break;
            end
        end
    end

    fileList(cellfun('isempty', fileList(:,3)), :) = []; %remove entries without parameters
  
    % RPM limits
    % E   - 145000/D
    % F   - 145000/D
    % MR  - 105000/D
    % SF  - 65000/D
    % E-3 - 270000/D
    % E-4 - 270000/D
    
    for ii = 1:size(fileList, 1) % depending on propeller series and diameter add speed limit parameter
        temp1 = fileList{ii,1};
        temp2 = temp1(isstrprop(temp1,'alpha'));
        switch temp2(2:end)
            case 'PN'
                SpeedLimitSet = 190000;
            case {'W' 'N' 'P'}
                SpeedLimitSet = 270000;
            case {'E' 'F' 'WE' 'EPN' 'ECD'}
                SpeedLimitSet = 145000;
            case 'MR'
                SpeedLimitSet = 105000;
            case 'SF'
                SpeedLimitSet = 65000;
            case {'E-3' 'E-4' 'C'}
                SpeedLimitSet = 270000;
            otherwise
                SpeedLimitSet = 225000;
        end
        fileList{ii,6} = SpeedLimitSet/fileList{ii,3};
    end
    
    for ii = 1:size(fileList,1)
        p = Propeller();
        p.name = fileList{ii,1};
        p.file = fileList{ii,2};
        p.diameter = fileList{ii,3};
        p.pitch = fileList{ii,4};
        p.mass = fileList{ii,5};
        p.rpm_max = fileList{ii,6};
        propList(ii) = p;
    end
    
    output = propList;
end