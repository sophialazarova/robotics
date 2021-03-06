function avoidObstacleDyn( h, start_loc, target_loc, start_angle)
% AVOIDOBSTACLEDYN Navigates the robot from starting location A to
% target location B while avoiding any obstacles on the way. Uses dynamical
% approach. Takes into account the starting angle.
% 
% AVOIDOBSTACLEDYN(h, start_loc, target_loc, start_angle)
% @PARAM
% h - connection token.
% start_loc - starting location given as a vector in the format (x,y).
% target_loc - target location given as a vector in the format (x,y).
% start_angle - starting angle(orientation) given in radians [0,2Pi]

ROBOT_PROXIMITY_SENSORS_DIRECTIONS=[deg2rad(-15), deg2rad(-45), deg2rad(-90), deg2rad(-150), deg2rad(150), deg2rad(90), deg2rad(45), deg2rad(15)];
SPEED_CONST = 200;
notat_tar=true;
last_pos_pul = kGetEncoders(h);
current_loc_allo = start_loc;
current_angle = start_angle;
hold on
    while(notat_tar)
        %% calculate location & angle change
        new_pos_pul = kGetEncoders(h);
        delta_pos_allo = getDeltaPosition(last_pos_pul, new_pos_pul, current_angle);

        %% update location and angle
        %delta_pos_allo
        current_angle = wrapToPi(current_angle + delta_pos_allo(3));
        current_loc_allo = current_loc_allo + [delta_pos_allo(1),delta_pos_allo(2)];
        plot(current_loc_allo(1),current_loc_allo(2),'o');
        drawnow
        xlim([0,400]);
        ylim([0,400]);
        xlabel('x (mm)');
        ylabel('y (mm)');
        %% get direction and distance to target
        angle_dist_tar = getAngleDistanceTarget(target_loc, current_loc_allo);
        
        %% get distance to obstacles
        dist_obstacles = getDistanceToObstcls(h);
        
        %% get angles to obstacles
        psi_obs = (ROBOT_PROXIMITY_SENSORS_DIRECTIONS+current_angle);
        
        %% calculate attractor contribution
        delta_phi_attr = getAttractorContribution(current_angle, angle_dist_tar(1));
        
        %% calculate repellor contribution
        delta_phi_repellors = getRepellorsContribution(dist_obstacles,psi_obs,current_angle);
        
        %% calculate joint attractor+repellor contribution
        delta_phi=delta_phi_attr+delta_phi_repellors;
        
        %% calculate speed
        %delta_phi_attr
        right_left_vel = getVelocities(delta_phi);
        
        %% apply speed
        %right_left_vel
        kSetSpeed(h,right_left_vel(2)+SPEED_CONST, right_left_vel(1)+SPEED_CONST);
        
        %% update pulse tracking variable
        last_pos_pul = new_pos_pul;
        
        %% check if target is reached
        dist_to_tar=sqrt(power(target_loc(1)-current_loc_allo(1),2) + power(target_loc(2)-current_loc_allo(2),2));
        if(dist_to_tar<20)
            notat_tar = false;
            kStop(h);
        end 
    end
end

function distances_obstcl = getDistanceToObstcls(h)
    CALIBRATION_VALUES=[3500,3;3900,3;3700,3;3900,3;3900,3;4000,3;4000,3;4000,3];
    distances_obstcl = zeros(1,8);
    
    sensors_output = kProximity(h);
    for i=1:1:8
        range = CALIBRATION_VALUES(i,:);
        
        norm_proximity=(sensors_output(i)-range(2))/(range(1)-range(2));
        %proximity_cm =-1.3*log(normalizedValue)-1.3;
        distances_obstcl(1,i)=-1.3*log(norm_proximity)-1.3;
    end
end

function delta_phi_repellors = getRepellorsContribution(dist_obs, psi_obs, current_angle)
    BETA_1=8.8;
    BETA_2=6.3;
    delta_theta = degtorad(60); %%% ?

    %% calculate strength of repulsion
    lambda_obs = zeros(1,8);
    for i=1:1:8
        lambda_obs(i) =  BETA_1 * exp(-dist_obs(i) / BETA_2 );
    end
    zeta = current_angle-psi_obs; 
    delta_phi_obs =  lambda_obs .* zeta .* exp(-(zeta.^2)./ (2 * (delta_theta^2)));
    
    delta_phi_repellors=sum(delta_phi_obs);
end
