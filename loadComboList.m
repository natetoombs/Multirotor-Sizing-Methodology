% Loads list from ComboList&Data.xlsx for filtering

function output = loadComboList()
    list = readtable('ComboList&Data.xlsx','Sheet','List');
    
    j = 1;
    for iRow = 1:size(list,1)
        if list{iRow,'Use'} == 1
            combo = Combo();
            combo.motorName = list{iRow,'Motor'}{1};
            combo.propName = list{iRow,'Propeller'}{1};
            combo.propDiameter = list{iRow,'Diameter'};
            combo.speedLimit = list{iRow,'MaxSpeed'};
            combo.massCombined = list{iRow,'Mass'};
            combo.currentRating = list{iRow,'MaxCurrent'};
            output(j) = combo;
            j = j + 1;
        end
    end