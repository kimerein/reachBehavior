function out=parseSerialOut(filename,outfile)

% filename specifies a text file, the serial output from Arduino written to
% microSD card

% Set up variables here
uint8 loaderWriteCode;
uint8 pelletsWriteCode;
uint8 encoderWriteCode;
uint8 cueWriteCode;
uint8 distractorWriteCode;
uint8 dropWriteCode;
uint8 missWriteCode;
uint8 beginTrialWrite;
single eventTime;

loaderWriteCode = 1;
pelletsWriteCode = 2;
encoderWriteCode = 3;
cueWriteCode = 4;
distractorWriteCode = 5;
dropWriteCode = 6;
missWriteCode = 7;
beginTrialWrite = 0;

maxITI=30000; % maximum duration of trial in ms
showExampleTrial=1;

% Stores data about behavior expt
ITIs=[];
eventLog=[];
eventLogTimes=[];
encoderPosition=[];
cueStart=[]; % 0 if cue is starting, 1 if cue is stopping
distractorStart=[]; % 0 if distractor is starting, 1 if distractor is stopping
trialDropCount=[]; % counts up pellets dropped during trial
trialMissCount=[]; % counts up pellets missed during trial

% Open file
fid=fopen(filename);

% Read lines
eventWriteCode=nan;
eventInfo=nan;
eventTime=nan;
cline=fgetl(fid);
while cline~=-1
    disp(cline);
    % is -1 at eof
    % parse
    breakInds=regexp(cline,'>');
    if isempty(breakInds) || strcmp(cline,'skip')
        % discard this line
        cline=fgetl(fid);
        if isempty(cline)
            cline='skip';
        end
        continue
    elseif length(breakInds)==1
        % format of this line is eventWriteCode then eventInfo
        eventWriteCode=str2double(cline(1:breakInds(1)-1));
        eventInfo=str2double(cline(breakInds(1)+1:end));
    elseif length(breakInds)==2
        % format of this line is eventWriteCode, eventInfo, then eventTime
        eventWriteCode=str2double(cline(1:breakInds(1)-1));
        eventInfo=cline(breakInds(1)+1:breakInds(2)-1);
        eventTime=single(str2double(cline(breakInds(2)+1:end)));
    else
        % problem
        error('improperly formatted line');
    end
    % get data
    switch eventWriteCode
        case beginTrialWrite % trial begins
            ITIs=[ITIs str2double(eventInfo)];
            eventLog=[eventLog eventWriteCode];
            eventLogTimes=[eventLogTimes eventTime];
        case loaderWriteCode % pellet is loaded
            eventLog=[eventLog eventWriteCode];
            eventLogTimes=[eventLogTimes eventTime];
        case pelletsWriteCode % pellet presentation wheel begins to turn
            eventLog=[eventLog eventWriteCode];
            eventLogTimes=[eventLogTimes eventTime];
        case encoderWriteCode % analog encoder reading
            eventLog=[eventLog eventWriteCode];
            eventLogTimes=[eventLogTimes eventTime];
            encoderPosition=[encoderPosition str2double(eventInfo)];
        case cueWriteCode % cue turns on or off
            eventLog=[eventLog eventWriteCode];
            eventLogTimes=[eventLogTimes eventTime];
            if strcmp(eventInfo,'S')
                cueStart=[cueStart 1];
            elseif strcmp(eventInfo,'E')
                cueStart=[cueStart 0];
            else
                error('unrecognized cue code info');
            end
        case distractorWriteCode % distractor turns on or off
            eventLog=[eventLog eventWriteCode];
            eventLogTimes=[eventLogTimes eventTime];
            if strcmp(eventInfo,'S')
                distractorStart=[distractorStart 1];
            elseif strcmp(eventInfo,'E')
                distractorStart=[distractorStart 0];
            else
                error('unrecognized distractor code info');
            end
        case dropWriteCode % dropped pellet count
            trialDropCount=[trialDropCount eventInfo];
        case missWriteCode % missed pellet count
            trialMissCount=[trialMissCount eventInfo];
        otherwise
            error('unrecognized write code');
    end
    cline=fgetl(fid);
    if isempty(cline)
        cline='skip';
    end
end
out.eventLog=eventLog;
out.eventLogTimes=eventLogTimes;
out.trialDropCount=trialDropCount;
out.trialMissCount=trialMissCount;
out.distractorStart=distractorStart;
out.cueStart=cueStart;
out.encoderPosition=encoderPosition;
out.ITIs=ITIs;

% Re-structure data as trial-by-trial
timesPerTrial=0:1:maxITI; % in ms
pelletLoaded=zeros(length(ITIs),length(timesPerTrial));
pelletPresented=zeros(length(ITIs),length(timesPerTrial));
encoderTrialVals=nan(length(ITIs),length(timesPerTrial));
cueOn=zeros(length(ITIs),length(timesPerTrial));
distractorOn=zeros(length(ITIs),length(timesPerTrial));
nDropsPerTrial=nan(length(ITIs),length(timesPerTrial));
nMissesPerTrial=nan(length(ITIs),length(timesPerTrial));
allTrialTimes=nan(length(ITIs),length(timesPerTrial));
startIndsIntoEventLog=find(eventLog==beginTrialWrite);
all_distractorEvents=find(eventLog==distractorWriteCode);
all_cueEvents=find(eventLog==cueWriteCode);
timeSoFar=0;
for i=1:length(ITIs)
    currITI=ITIs(i);
    allTrialTimes(i,timesPerTrial<=currITI)=timesPerTrial(timesPerTrial<=currITI);
    if i==length(ITIs)
        relevantEventLog=eventLog(startIndsIntoEventLog(i):end);
        relevantEventLogTimes=eventLogTimes(startIndsIntoEventLog(i):end);
        isCurrentTrial=zeros(1,length(eventLog));
        isCurrentTrial(startIndsIntoEventLog(i):end)=1;
    else
        relevantEventLog=eventLog(startIndsIntoEventLog(i):startIndsIntoEventLog(i+1)-1);
        relevantEventLogTimes=eventLogTimes(startIndsIntoEventLog(i):startIndsIntoEventLog(i+1)-1);
        isCurrentTrial=zeros(1,length(eventLog));
        isCurrentTrial(startIndsIntoEventLog(i):startIndsIntoEventLog(i+1)-1)=1;
    end
    % Change times to wrt start of this trial
    relevantEventLogTimes=relevantEventLogTimes-eventLogTimes(startIndsIntoEventLog(i));
    timeSoFar=timeSoFar+currITI;
    % Find time when pellet loaded
    curr=relevantEventLogTimes(relevantEventLog==loaderWriteCode);
    if length(curr)>1 % Should have only loaded pellet once
        error('Why has pellet been loaded more than once?');
    else
        [~,mi]=min(abs(timesPerTrial-curr)); % Find closest time
        pelletLoaded(i,mi(1))=1; % Loaded here
    end
    % Find time when pellet wheel begins to turn
    curr=relevantEventLogTimes(relevantEventLog==pelletsWriteCode);
    if length(curr)>1 % Should have only presented pellet once
        error('Why has pellet been presented more than once?');
    else
        [~,mi]=min(abs(timesPerTrial-curr)); % Find closest time
        pelletPresented(i,mi(1))=1; % Loaded here
    end
    % Enter encoder position per trial
    if length(ITIs)~=length(encoderPosition) % should be same length
        error('Number of trials should equal number of encoder position values');
    else
        encoderTrialVals(i,:)=encoderPosition(i);
    end
    % Find time of distractor on
    curr_distractorEvents=find(isCurrentTrial==1 & eventLog==distractorWriteCode);
    indsIntoLedStarts=find(ismember(all_distractorEvents,curr_distractorEvents));
    curr=relevantEventLogTimes(relevantEventLog==distractorWriteCode);
    startsOn=1;
    for j=1:length(curr) % iterate through changes in distractor state
        stateChange=distractorStart(indsIntoLedStarts(j));
        if stateChange==1 % distractor is turning on
            startsOn=0;
            [~,mi]=min(abs(timesPerTrial-curr(j))); % Find closest time
            distractorOn(i,mi(1):end)=1;
        elseif stateChange==0 % distractor is turning off
            [~,mi]=min(abs(timesPerTrial-curr(j))); % Find closest time
            distractorOn(i,mi(1):end)=0;
            if startsOn==1
                distractorOn(i,1:mi(1)-1)=1;
            end
            startsOn=0;
        else
            error('stateChange value should be 0 or 1');
        end
    end
    % Find time of cue on
    curr_cueEvents=find(isCurrentTrial==1 & eventLog==cueWriteCode);
    indsIntoLedStarts=find(ismember(all_cueEvents,curr_cueEvents));
    curr=relevantEventLogTimes(relevantEventLog==cueWriteCode);
    startsOn=1;
    for j=1:length(curr) % iterate through changes in distractor state
        stateChange=cueStart(indsIntoLedStarts(j));
        if stateChange==1 % distractor is turning on
            startsOn=0;
            [~,mi]=min(abs(timesPerTrial-curr(j))); % Find closest time
            cueOn(i,mi(1):end)=1;
        elseif stateChange==0 % distractor is turning off
            [~,mi]=min(abs(timesPerTrial-curr(j))); % Find closest time
            cueOn(i,mi(1):end)=0;
            if startsOn==1
                cueOn(i,1:mi(1)-1)=1;
            end
            startsOn=0;
        else
            error('stateChange value should be 0 or 1');
        end
    end
    % Enter number of drops per trial
    if length(ITIs)~=length(trialDropCount) % should be same length
        error('Number of trials should equal number of trial drop counts');
    else
        if i==1
            beforeDrops=0;
        else
            beforeDrops=nanmean(nDropsPerTrial(i-1,:),2);
        end
        nDropsPerTrial(i,:)=trialDropCount(i)-beforeDrops;
    end
    % Enter number of misses per trial
    if length(ITIs)~=length(trialMissCount) % should be same length
        error('Number of trials should equal number of trial miss counts');
    else
        if i==1
            beforeDrops=0;
        else
            beforeDrops=nanmean(nMissesPerTrial(i-1,:),2);
        end
        nMissesPerTrial(i,:)=trialMissCount(i)-beforeDrops;
    end
end
out.pelletLoaded=pelletLoaded;
out.timesPerTrial=timesPerTrial;
out.pelletPresented=pelletPresented;
out.encoderTrialVals=encoderTrialVals;
out.cueOn=cueOn;
out.distractorOn=distractorOn;
out.nDropsPerTrial=nDropsPerTrial;
out.nMissesPerTrial=nMissesPerTrial;
out.allTrialTimes=allTrialTimes;

if showExampleTrial==1
    figure();
    subplot(4,1,1);
    plot(timesPerTrial,nanmean(pelletLoaded,1));
    subplot(4,1,2);
    plot(timesPerTrial,nanmean(pelletPresented,1));
    subplot(4,1,3);
    plot(timesPerTrial,nanmean(cueOn,1));
    subplot(4,1,4);
    plot(timesPerTrial,distractorOn(9,:));
end

fclose(fid);

% Save data
save(outfile,'out');

    
    
    