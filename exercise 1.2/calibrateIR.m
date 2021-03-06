function sensor_mean_readings = calibrateIR(h,tests_count,sensor_id)
% CALIBRATEIR Runs a calibration sequence for the infrared sensors given number of times. As a result returns the mean readings from the trials
% and the standart deviation for the specified sensor.
% 
% sensor_mean_readings = CALIBRATEIR(h,tests_count,sensor_id)
% @PARAM
% h - connection token
% tests_count - sets the number of test trials to be executed.
% sensor_id - specifies a sensor by providing number in the range [1;8].
% @RETURN
% sensor_mean_readings - a two-value vector that contains the mean value obrained
% across the trial as a first element and the standart deviation as second.

test_results = runTest(h,tests_count);
mean_values = getMean(test_results,tests_count);
std_values = getStd(test_results,tests_count);

mean_sensor_i = mean_values(sensor_id);
std_sensor_i = std_values(sensor_id);
sensor_mean_readings = [mean_sensor_i; std_sensor_i];
end

function res = runTest(h,n)
m=0.0;
m(n,8) = 0.0;

    for i=1:1:n
        sensorReadings = kProximity(h);
        for j=1:1:8
            m(i,j) = sensorReadings(j);
        end
    end
res =m;
end

function sensorStd=getStd(matrix,n)
sensorStd = [0;0;0;0;0;0;0;0];
    for i=1:1:8
        column = matrix(:,i);
        sensorStd(i)=std(column);
    end
end

function sensors_means = getMean(matrix,n)
temp = 0;
sensors_means=[0;0;0;0;0;0;0;0];
    for i=1:1:8
        for j=1:1:n
            temp = temp + matrix(j,i);
        end
        sensors_means(i)=temp/n;
        temp=0;
    end
end
