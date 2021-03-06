function avoidObstacleAlg(h,p1,p2,start_angle)
% AVOIDOBSTACLEALG Navigates the robot from starting location p1 to targat location p2 while
% avoiding any obstacles on the way. Algorithmic solution, no hardcoded
% values. Takes into account the starting angle of the robot and uses wheel sensors
% to monitor further location and orientation.
% 
% AVOIDOBSTACLEALG(h,p1,p2,start_angle)
% @PARAM
% h - connection token 
% p1 - vector denoting the starting location given in format (x,y)
% p2 - vector denoting the target location given in format (x,y)
% start_angle - initial orientation of the robot in the environment.

    last_pulses_readings = [0;0];
    current_angle = start_angle;
    last_plot_location = p1;
    calibration_values = [3500,3;3900,3;3700,3;3900,3;3900,3;4000,3;4000,3;4000,3];
    passed_obstacle = false;
    not_at_target = true;
    
    hold on
    xlim([0,270]);
    ylim([0,400]);
    while(not_at_target)
        %%check if at target
        distance_to_target=sqrt(power(p2(1)-last_plot_location(1),2) + power(p2(2)-last_plot_location(2),2));
        if(distance_to_target<40)
            not_at_target = false;
            kStop(h);
        end 
        
        %%
        angle_to_target = getAngle(p2,last_plot_location,current_angle);
        if(angle_to_target >= deg2rad(0) && angle_to_target < deg2rad(2))
            %% target is straight ahead
            proximity_readings = kProximity(h);
            proximity_value_first = normalizeInRange(proximity_readings(1),calibration_values(1,:));
            proximity_value_eight = normalizeInRange(proximity_readings(8),calibration_values(8,:));
            proximity_value_cm = convertCm((proximity_value_first+proximity_value_eight)/2);
            while(proximity_value_cm>=4.3)
                %% no obstacle ahead -> move straight in direction to target
                distance_to_target=sqrt(power(p2(1)-last_plot_location(1),2) + power(p2(2)-last_plot_location(2),2));
                if(distance_to_target<10)
                   not_at_target = false;
                   kStop(h);
                   return;
                end 

                %% plot %%
                updatePlot(last_plot_location(1),last_plot_location(2));
                xlabel('x (mm)');
                ylabel('y (mm)');

                proximity_readings = kProximity(h);
                proximity_value_first = normalizeInRange(proximity_readings(1),calibration_values(1,:));
                proximity_value_eight = normalizeInRange(proximity_readings(8),calibration_values(8,:));
                proximity_value_cm=convertCm((proximity_value_first+proximity_value_eight)/2);

                kSetSpeed(h,200,200);
                current_location_stats = updateMovementStatsStraight(h,last_plot_location, last_pulses_readings,current_angle);
                last_pulses_readings = [current_location_stats(1);current_location_stats(2)];
                last_plot_location = [current_location_stats(3);current_location_stats(4)];
            end
            %% obstacle detected within 4 cm -> rotate 60deg and avoid
            kSetSpeed(h,-100,100);
            angle_threshold=current_angle+deg2rad(60);
            while(~(current_angle > angle_threshold-deg2rad(2) && current_angle<angle_threshold+deg2rad(2)))
                %% rotation loop
                kSetSpeed(h,-100,100);
                current_pulses_readings = kGetEncoders(h);
                distance_pulses = current_pulses_readings-last_pulses_readings;
                distancemm = computeDistancemm(distance_pulses);
                displacement_angle=distancemm(2)/26.5;
                %% update values
                current_angle = wrapToPi(current_angle+displacement_angle);
                last_pulses_readings = current_pulses_readings;
            end
            %% move forward after rotation
            kSetSpeed(h,200,200);
            passed_obstacle=true;
 
        elseif(passed_obstacle==true)
            %% pass aside of the obstacle with straight movement
            pulses_after_rotation = last_pulses_readings;
            while(1)
                %% plot %%
                updatePlot(last_plot_location(1),last_plot_location(2));
                
                kSetSpeed(h,200,200);
                current_location_stats = updateMovementStatsStraight(h,last_plot_location, last_pulses_readings,current_angle);
                
                %% update values %%
                last_pulses_readings = [current_location_stats(1);current_location_stats(2)];
                last_plot_location = [current_location_stats(3);current_location_stats(4)];
                
                %% obstacle is left somewhere aside -> succesfully avoided %%
                if(last_pulses_readings(2) > pulses_after_rotation + 700)                   
                    passed_obstacle=false;
                    kStop(h);
                    break;
                end
            end
        else
            %% obstacle passed -> reorient towards target 
            angle_threshold=current_angle+angle_to_target;
            while(~(current_angle > angle_threshold-deg2rad(2) && current_angle<angle_threshold+deg2rad(2)))
                %rotation loop
                kSetSpeed(h,-100,100);
                
                %% plot %%
                updatePlot(last_plot_location(1),last_plot_location(2));
                
                %% calculate angular displacement
                current_pulses_readings = kGetEncoders(h);
                distance_pulses=current_pulses_readings-last_pulses_readings;
                distancemm = computeDistancemm(distance_pulses);
                displacement_angle=distancemm(2)/26.5;
                
                %% update values
                current_angle = wrapToPi(current_angle+displacement_angle);
                last_pulses_readings = current_pulses_readings;
            end
        end
    end
end

%% private functions 
function updatePlot(x,y)
    plot(x,y,'o');
    drawnow
    xlim([0,270]);
    ylim([0,400]);
end

function stats = updateMovementStatsStraight(h,lastPlotPosition, lastPulsesNum,currentAngle)
    pathValues = kGetEncoders(h);
    distance=pathValues-lastPulsesNum;
    distancemm = computeDistancemm(distance);
    egocentric = [distancemm(1)*cos(currentAngle), distancemm(1)*(sin(currentAngle))];
    allocentricRate = [lastPlotPosition(1)+egocentric(1), lastPlotPosition(2)+egocentric(2)];
    %%update values
    stats(1) = pathValues(1);
    stats(2) = pathValues(2);
    stats(3) = allocentricRate(1);
    stats(4) =allocentricRate(2);
end
function angle = getAngle(target,currentPosition,currentAngle)
    a = target(1)-currentPosition(1); % a side of the triangle
    b = target(2)-currentPosition(2); % b side of the triangle
    angleTemp = atan2(b,a); % angle between current position and target center
    angle=angleTemp-currentAngle; 
end

