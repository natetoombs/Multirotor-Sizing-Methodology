% Rounds the battery cell number to the nearest even integer.

function roundedBatteryCellNo = roundBatteryCellNo(BatteryCellNo)
    if mod(BatteryCellNo,2) >= 1
        roundedBatteryCellNo = ceil(BatteryCellNo+1e-15);
    else
        roundedBatteryCellNo = floor(BatteryCellNo);
    end
end