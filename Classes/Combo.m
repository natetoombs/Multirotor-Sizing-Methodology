% Class for each motor/propeller combination. Includes operating points as
% well.

classdef Combo
    properties
        motorName
        propName
        propDiameter
        massCombined
        currentRating
        powerHover
        powerMax
        speedHover
        speedMax
        thrustHover
        thrustMax
        speedLimit
        voltage
    end
end