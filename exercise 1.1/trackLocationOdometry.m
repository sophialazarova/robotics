function trackLocationOdometry(h,initial_position,initial_orientation_degrees)
% TRACKLOCATIONODOMETRY Sets a sequence of random movements and tracks the movement of the robot while executing it.
% The movement of the robot is plotted into a visual representation showing the previous path of the robot and its
% current location. Uses the readings from the wheel sensors to estimate
% the current location and orientation of the robot based on a given initial position and orientation.
% 
% TRACKLOCATIONODOMETRY(h,initial_position,initial_orientation_degrees)
% @PARAM
% h - connection token.
% initial_position - starting location given as a vector in the format (x,y).
% orientation_degrees - initial orientation in degrees

%%%%%FIXED PROGRAM%%%%%
%DO NOT CHANGE OR USE ANY VARIABLES HERE
global curInterval
global timeStamp
global curCommandCode
global movementCounter
curInterval = [];
timeStamp = [];
curCommandCode = [];
movementCounter = 0;
isStillMoving = true;
%%%%%END FIXED PROGRAM%%%%%

last_measured_pulses = [0;0];
current_angle = deg2rad(initial_orientation_degrees);
last_plot_location = initial_position;

current_location_marker = rectangle('Position',[last_plot_location(1),last_plot_location(2),20,20]);
current_location_marker.EdgeColor = 'none';
current_location_marker.FaceColor = 'blue';
axis equal

ylim([0 400])

%%%%%FIXED PROGRAM%%%%%
%DO NOT CHANGE OR USE ANY VARIABLES HERE   
    while(isStillMoving)        
        isStillMoving = randomMovement(h);
        %%%%%END FIXED PROGRAM%%%%%

        current_path_pulses=kGetEncoders(h);
        
        %% calculate displacement between last known location and current location
        distance_pulses=current_path_pulses-last_measured_pulses;
        distancemm = computeDistancemm(distance_pulses);
        
        if (distance_pulses(1)==distance_pulses(2))
            %% case: moving straight
            %% plot path
            path_marker = rectangle('Position',[last_plot_location(1),last_plot_location(2),5,5]);
            path_marker.FaceColor = 'red';
            path_marker.EdgeColor = 'none';

            %% calculate current position
            location_displacement = [distancemm(1)*cos(current_angle), distancemm(1)*(sin(current_angle))];
            current_location = [last_plot_location(1)+location_displacement(1), last_plot_location(2)+location_displacement(2)];

            %% plot marker at current location
            current_location_marker.Position = [current_location(1), current_location(2),15,20];

            %% update values
            last_measured_pulses = current_path_pulses;
            last_plot_location = current_location;
            drawnow limitrate
        
        elseif (distance_pulses(1)==-distance_pulses(2))
            %% case: in place rotation
            angle_displacement=distancemm(2)/26.5;

            %% update values
            current_angle = current_angle+angle_displacement;
            last_measured_pulses = current_path_pulses;
        
        else
            %% case: arc movement
            %% print path %%
            path_marker = rectangle('Position',[last_plot_location(1),last_plot_location(2),5,5]);
            path_marker.FaceColor = 'red';
            path_marker.EdgeColor = 'none';

            %% calculate current position %%
            angle_displacement=((distancemm(2)-distancemm(1))/53.0);
            radius= ((((distancemm(1)+distancemm(2))/2.0)*53.0)/(distancemm(2)-distancemm(1)));
            xego = radius*sin(angle_displacement);
            yego = radius*(1-cos(angle_displacement));
            xallo=xego*cos(current_angle)-yego*sin(current_angle);
            yallo=xego*sin(current_angle)+yego*cos(current_angle);
            current_location = [last_plot_location(1)+xallo, last_plot_location(2)+yallo];

            %% draw marker at current location
            current_location_marker.Position = [current_location(1), current_location(2),15,20];

            %% update values
            last_measured_pulses = current_path_pulses;
            last_plot_location = current_location;
            current_angle = current_angle+angle_displacement;
            drawnow limitrate 
        end
    end
end

