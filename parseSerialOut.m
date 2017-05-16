function parseSerialOut(filename)

% filename specifies a text file, the serial output from Arduino written to
% microSD card

% Set up variables here
uint loaderWriteCode
uint pelletsWriteCode
uint encoderWriteCode
uint cueWriteCode
uint distractorWriteCode
uint dropWriteCode
uint missWriteCode
uint beginTrialWrite
single eventTime

loaderWriteCode = 1;
pelletsWriteCode = 2;
encoderWriteCode = 3;
cueWriteCode = 4;
distractorWriteCode = 5;
dropWriteCode = 6;
missWriteCode = 7;
beginTrialWrite = 0;

maxITI=30000; % maximum duration of trial in ms

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
cline=fgets(fid);
while cline~=-1
    % is -1 at eof
    % parse
    breakInds=regexp(cline,'>');
    if isempty(breakInds)
        % discard this line
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
        case 0 % trial begins
            ITIs=[ITIs str2double(eventInfo)];
            eventLog=[eventLog eventWriteCode];
            eventLogTimes=[eventLogTimes eventTime];
        case 1 % pellet is loaded
            eventLog=[eventLog eventWriteCode];
            eventLogTimes=[eventLogTimes eventTime];
        case 2 % pellet presentation wheel begins to turn
            eventLog=[eventLog eventWriteCode];
            eventLogTimes=[eventLogTimes eventTime];
        case 3 % analog encoder reading
            eventLog=[eventLog eventWriteCode];
            eventLogTimes=[eventLogTimes eventTime];
            encoderPosition=[encoderPosition str2double(eventInfo)];
        case 4 % cue turns on or off
            eventLog=[eventLog eventWriteCode];
            eventLogTimes=[eventLogTimes eventTime];
            if strcmp(eventInfo,'S')
                cueStart=[cueStart 1];
            elseif strcmp(eventInfo,'E')
                cueStart=[cueStart 0];
            else
                error('unrecognized cue code info');
            end
        case 5 % distractor turns on or off
            eventLog=[eventLog eventWriteCode];
            eventLogTimes=[eventLogTimes eventTime];
            if strcmp(eventInfo,'S')
                distractorStart=[distractorStart 1];
            elseif strcmp(eventInfo,'E')
                distractorStart=[distractorStart 0];
            else
                error('unrecognized distractor code info');
            end
        case 6 % dropped pellet count
            trialDropCount=[trialDropCount eventInfo];
        case 7 % missed pellet count
            trialMissCount=[trialMissCount eventInfo];
        otherwise
            error('unrecognized write code');
    end
end


% Re-structure data as trial-by-trial
timesPerTrial=0:1:maxITI; % in ms
pelletLoaded=zeros(length(ITIs),length(timesPerTrial));
pelletPresented=zeros(length(ITIs),length(timesPerTrial));
encoderPosition=nan(length(ITIs),length(timesPerTrial));
cueOn=zeros(length(ITIs),length(timesPerTrial));
distractorOn=zeros(length(ITIs),length(timesPerTrial));
nDropsPerTrial=nan(length(ITIs),length(timesPerTrial));
nMissesPerTrial=nan(length(ITIs),length(timesPerTrial));
allTrialTimes=nan(length(ITIs),length(timesPerTrial));
startIndsIntoEventLog=find(eventLog==beginTrialWrite);
for i=1:length(ITIs)
    currITI=ITIs(i);
    allTrialTimes(i,timesPerTrial<=currITI)=timesPerTrial(timesPerTrial<=currITI);
    if i==length(ITIs)
        relevantEventLog=eventLog(startIndsIntoEventLog(i):end);
        relevantEventLogTimes=eventLogTimes(startIndsIntoEventLog(i):end);
    else
        relevantEventLog=eventLog(startIndsIntoEventLog(i):startIndsIntoEventLog(i+1)-1);
        relevantEventLogTimes=eventLogTimes(startIndsIntoEventLog(i):startIndsIntoEventLog(i+1)-1);
    end
    
    
    
    
    