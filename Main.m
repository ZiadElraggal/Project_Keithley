% Initialize parameters
obj = visadev("USB0::0x0XXX::0xXXXX::XXXXXX::0::INSTR");
obj.Timeout=20;
numTemps = 132;
Intervalmin = 1;
Durationhrs = 1;
Names = {'ex1', 'ex2', 'ex3', 'ex4', 'ex5', 'ex6', 'ex7', 'ex8', 'ex9', 'ex10', 'ex11', 'ex12'};
num = numel(Names);

% Generate point names
pointNames = cell(1, numTemps);
for n = 1:num
    for i = 1:11
        pointNames{(n-1)*11 + i} = [Names{n}, num2str(i)];
    end
end

% Initialize data storage
temperatureData = cell(1, 0);
timestamps = NaT(0, 1);

% Instrument setup
writeline(obj, 'reset()');

% Data collection loop
startTime = tic;
while toc(startTime) < (Durationhrs * 3600)
    i = length(temperatureData) + 1;
    x = datetime('now', 'Format', 'HH:mm:ss');
    temperatureMeasurements = measureTemperature(obj);

    temperatureData{i} = temperatureMeasurements;
    timestamps(i, 1) = x;
    
    minLength = min([length(pointNames), numel(temperatureData), length(timestamps)]);
    numGraphs = ceil(numel(temperatureData) / 11);

    for graphIndex = 1:numGraphs
        figure;
        for n = 1:num
            subplot(3, 4, n);
            hold on;
            Indices = (n-1)*11 + 1:n*11;

            for i = (graphIndex-1)*11 + 1 : min(graphIndex*11, minLength)
                currentTimestamp = timestamps(i);

                if numel(temperatureData{i}) >= max(Indices)
                    color = hsv2rgb([n/num, 1, 1]);
                    scatter(repmat(currentTimestamp, 1, length(Indices)), temperatureData{i}(Indices),"MarkerEdgeColor",color,"Marker", '*', 'DisplayName', '');

                    for j = 1:length(Indices)
                        dataIndex = Indices(j);

                        if dataIndex <= numTemps
                            text(currentTimestamp, temperatureData{i}(dataIndex), [pointNames{dataIndex}, '', ''], 'FontSize', 8, 'HorizontalAlignment', 'right');
                        end
                    end
                end
            end

            hold off;
            xlabel('Timestamp');
            ylabel('Temperature (Celsius)');
            title(['Temperature Measurements - ', Names{n}]);
            grid on;
        end

        pause(Intervalmin * 10);
        close(gcf);
    end
end

% Clean up
delete(obj);

% Write data to Excel file

% Initialize cell array to store data
dataCell = cell(numel(temperatureData), 0);

% Organize data into cell array with headers
for i = 1:numel(temperatureData)
    data = temperatureData{i};
    tempCell = cell(11, numel(Names));
    for j = 1:numel(Names)
        startIdx = (j - 1) * 11 + 1;
        endIdx = j * 11;
        tempCell(:, j) = num2cell(data(startIdx:endIdx));
    end
    dataCell{i} = tempCell;
end

% Create a table to store the data
dataTable = table(timestamps, 'VariableNames', {'Timestamp'});
for i = 1:numel(Names)
    for j = 1:11
        varName = strcat(Names{i}, num2str(j));
        dataColumn = nan(numel(temperatureData), 1);
        for k = 1:numel(temperatureData)
            dataColumn(k) = dataCell{k}{j, i};
        end
        dataTable.(varName) = dataColumn;
    end
end

% Write data to Excel file
filename = strcat("TempData", "_", datestr(now,'dd-mm-yyyy_HH.MM.SS'), '.xlsx');
writetable(dataTable, filename);


% Determine minimum length for plotting
minLength = min([length(pointNames), numel(temperatureData), length(timestamps)]);
numGraphs = ceil(numel(temperatureData) / 11);

% Plotting loop
for graphIndex = 1:numGraphs
    figure;
    for n = 1:num
        subplot(3, 4, n);
        hold on;
        Indices = (n-1)*11 + 1:n*11;

        for i = (graphIndex-1)*11 + 1 : min(graphIndex*11, minLength)
            currentTimestamp = timestamps(i);

            if numel(temperatureData{i}) >= max(Indices)
                color = hsv2rgb([n/num, 1, 1]);
                scatter(repmat(currentTimestamp, 1, length(Indices)), temperatureData{i}(Indices),"MarkerEdgeColor",color,"Marker", '*', 'DisplayName', '');

                for j = 1:length(Indices)
                    dataIndex = Indices(j);

                    if dataIndex <= numTemps
                        text(currentTimestamp, temperatureData{i}(dataIndex), [pointNames{dataIndex}, '', ''], 'FontSize', 8, 'HorizontalAlignment', 'right');
                    end
                end
            end
        end

        hold off;
        xlabel('Timestamp');
        ylabel('Temperature (Celsius)');
        title(['Temperature Measurements - ', Names{n}]);
        grid on;
    end
    saveas(gcf, strcat("TempGraph_", num2str(graphIndex), "_", datestr(now, 'HH_MM_SS_dd-mm-yyyy'), '.fig'));
end
%%
% Measurement function
function temperature = measureTemperature(obj)
    writeline(obj, 'channel.open("allslots")');	  
    writeline(obj, 'reading_buffer = dmm.makebuffer(1000)');				
    writeline(obj, 'dmm.func = dmm.TEMPERATURE');					
    writeline(obj, 'dmm.nplc = 1');
    writeline(obj, 'dmm.transducer = dmm.TEMP_THERMOCOUPLE');			
    writeline(obj, 'dmm.refjunction = dmm.REF_JUNCTION_INTERNAL');	
    writeline(obj, 'dmm.thermocouple = dmm.THERMOCOUPLE_J');			
    writeline(obj, 'dmm.units = dmm.UNITS_CELSIUS');			
    writeline(obj, 'dmm.configure.set("mytemp")');
    writeline(obj, 'dmm.setconfig("XXXX:XXXX,"mytemp")')	
    writeline(obj, 'scan.create("XXXX:XXXX")')
    writeline(obj, 'scan.execute(reading_buffer)')
    responseString1 = writeread(obj, 'printbuffer(1, reading_buffer.n, reading_buffer)');
    writeline(obj, 'dmm.setconfig("XXXX:XXXX","mytemp")')	
    writeline(obj, 'scan.create("XXXX:XXXX")')
    writeline(obj, 'scan.execute(reading_buffer)')
    responseString2 = writeread(obj, 'printbuffer(1, reading_buffer.n, reading_buffer)');
    writeline(obj, 'dmm.setconfig("XXXX:XXXX","mytemp")')
    writeline(obj, 'scan.create("XXXX:XXXX")')
    writeline(obj, 'scan.execute(reading_buffer)')
    responseString3 = writeread(obj, 'printbuffer(1, reading_buffer.n, reading_buffer)');
    responseString = append(responseString1, responseString2, responseString3);
    
    valuesStr = strsplit(responseString);
    temperature = str2double(valuesStr);
    
    overflowThreshold = 9.900000000e+37;
    temperature(temperature == overflowThreshold) = NaN;
    invalidIndices = isnan(temperature);
    temperature(invalidIndices) = NaN;
    
    % Pad with NaNs to make the length divisible by 11
    remainder = mod(length(temperature), 11);
    if remainder > 0
        padding = 11 - remainder;
        for k = 1:padding
            temperature(end+1) = NaN;
        end
    end
end
