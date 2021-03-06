function navigateToTargetAlg(h,p1,p2,initial_orientation)
% NAVIGATETOTARGETALG Navigates robot from any given location A to any
% given target location B in the corresponding environment. Uses algorithmic
% solution, calculates path on a straight line. Takes into account the
% initial facing angle(allocentric) of the robot.
%
% NAVIGATETOTARGETALG(h,p1,p2,initial_orientation)
% @PARAM
% h - connection token.
% p1 - starting location given as a vector in the format (x,y).
% p2 - target location given as a vector in the format (x,y).
% initial_orientation - starting angle(orientation) given in radians [0,2Pi]
c = getDistance(p1,p2);
angle = getAngle(p1, p2, initial_orientation);
impulses = getImpulsesRotation(angle);
arc_length = getArcLength(angle, 26.5);
if(arc_length ~= 0) 
    rotate(h, impulses, arc_length);
end

speed = getSpeed(0.8, c);
impulses_forward = getImpulsesForward(c);
moveForward(h, impulses_forward, speed);
end

%% Private utility functions
function c = getDistance(p1,p2)
a = abs(p1(1)-p2(1)); % a side of the triangle
b = abs(p1(2)-p2(2)); % b side of the triangle
c = sqrt(power(a,2) + power(b,2));
end

function res = getAngle(p1,p2, start_angle)
a = p2(1)-p1(1); % a side of the triangle
b = p2(2)-p1(2); % b side of the triangle
angle_temp = atan2(b,a); % angle between current position and target center
res=angle_temp-start_angle; 
end

function res = getImpulsesRotation(angle)
radius = 26.5; % radius of vehicle cirle
arcLengthmm = getArcLength(angle, radius);
res = 7.69*arcLengthmm; %7.69imp = 1mm 
end

function res = getArcLength(angle, radius)
res = angle*radius; %mm
end

function res = rotate(h, impulses, distance)
speed = getSpeed(0.2, distance);
kSetSpeed(h,-speed,speed);
    while (1)
    passedImpulses = kGetEncoders(h);
        if (abs(passedImpulses(1)) > abs(impulses))
            kStop(h);
            kSetEncoders(h, 0, 0);
            break;
        end
    res = 0;
    end
end

function res = getSpeed(time, distance)
res = distance/time;
end

function res = moveForward(h, distance, speed)
kSetSpeed(h, speed, speed)
    while(1)
        passedImpulses = kGetEncoders(h);
        abs(passedImpulses(1));
        if(abs(passedImpulses(1)) > distance)
            kStop(h);
            fprintf('STOP');
            break;
        end
    end
    res=0;
end

function res = getImpulsesForward(distancemm)
res = distancemm*7.69;
end

