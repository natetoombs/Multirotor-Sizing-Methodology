
% output = name, KV, mass, Io, Imax, Rm
function motorList = load_motorListx(voltage, prop_speedMax, prop_torqueMax, prop_speedHover, prop_torqueHover, spec_mass, brand)
    motors = {};
    [~, ~, raw] = xlsread('motorlist.xlsx');
        
    fileList = [{} {} {} {} {} {} {}];
    for ii = 2:size(raw,1) % skip first line
        fileList(ii-1,:) = [raw(ii,1:7)];
    end
    
    mBrand = fileList(:,1);
    mName = fileList(:,2); %mName = cell2mat(fileList(:,1));
    mKV = cell2mat(fileList(:,3));
    mMass = cell2mat(fileList(:,4));
    mIo = cell2mat(fileList(:,5));
    mImax = cell2mat(fileList(:,6));
    mRm = cell2mat(fileList(:,7));
    
    jj = 1;
    for ii = 1:size(mName,1)
        if isequal(mBrand{ii}, brand)
            ironLoss = voltage*mIo(ii);
            prop_powerMax = prop_torqueMax*prop_speedMax/60*2*pi; % calculate required propeller power at WOT
            prop_powerHover = prop_torqueHover*prop_speedHover/60*2*pi; % calculate required propeller power at hover
            motor_currentMax = (voltage - sqrt(voltage^2-4*mRm(ii)*(ironLoss+prop_powerMax)))/(2*mRm(ii)); % calculate motor current at WOT
            motor_currentHover = (voltage - sqrt(voltage^2-4*mRm(ii)*(ironLoss+prop_powerHover)))/(2*mRm(ii)); % calculate motor current at hover

            if isreal(motor_currentMax) && isreal(motor_currentHover) && motor_currentMax > 0 && motor_currentHover > 0 && mMass(ii) <= spec_mass &&...
                    motor_currentMax <= mImax(ii) % && 0.8*voltage*mKV(ii) > prop_speedMax
                motor_powerMaxEl = voltage*motor_currentMax; % calculate electrical power at WOT
                motor_effMax = prop_powerMax/(voltage*motor_currentMax)*100; % calculate efficiency at WOT
                motor_powerHoverEl = voltage*motor_currentHover; % calculate electrical power at WOT
                motor_effHover = prop_powerHover/(voltage*motor_currentHover)*100; % calculate efficiency at WOT

                motors(end+1,:) = {mBrand{ii,:}, mName{ii,:}, mImax(ii), mMass(ii), mKV(ii), mRm(ii),...
                                      motor_currentMax, motor_powerMaxEl, motor_effMax, ...
                                      motor_currentHover, motor_powerHoverEl, motor_effHover};
                m = Motor();
                [m.brand, m.name, m.Irating, m.mass, m.KV, m.Rm, m.Imax, m.Pmax, m.etamax,...
                    m.Ihover, m.Phover, m.etahover] = deal(motors{end,:});
                motorList(jj) = m;
                jj = jj + 1;
            end
        end
    end
    if ~exist('motorList')
        motorList = {};
    end
end