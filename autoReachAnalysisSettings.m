function settings=autoReachAnalysisSettings(varargin)

% user-set constants

persistent discardFirstNFrames chewThresh chronPath doManual

if ~isempty(varargin)
    discardFirstNFrames=varargin{1}; % number of frames to discard at beginning of movie
    if length(varargin)>1
        doManual=varargin{2};
        if length(varargin)>2
            chronPath=varargin{3};
            if length(varargin)>3
                chewThresh=varargin{4};
            end
        end
    end
end

% For all
settings.movie_fps=30; % movie frame rate in frames per second
settings.saveZoneData=1; % if 1, save zone data extracted from movie
settings.discardFirstNFrames=discardFirstNFrames; % number of frames to discard at beginning of movie
settings.isOrchestra=0; % if running this code on Harvard O2 server, set this to 1, else 0
settings.fixUnderpoweredDVR=false; % had a problem with the power supply to DVR for a few days, produced noise in video that needs to be corrected
settings.flipReachZone=false;

% For getReaches.m
settings.reach.userDefinedThresh=1; % set to 1 if want user to manually define threshold for reach, instead of automated method
if exist('doManual','var')
    if doManual==true
        settings.reach.userDefinedThresh=1; 
    end
end
settings.reach.doZscoreBeforeManual=true; % will Zscore raw reach data before asking user to set threshold
settings.reach.maxReachFrequency=6; % in Hz, the maximum frequency at which mouse can reach
settings.reach.reachThresh=2.5; % after non-parametric Z score transformation of reachData, threshold for determining mouse reach
settings.reach.holdThreshold=5; % in seconds -- if any reach lasts longer than 10 s, this is not a reach -- this is a hold
settings.reach.plotOutput=1; % if 1, plot output of reach analysis, else do not plot
settings.reach.Zscore=true; % if 1, will Zscore before asking user to set reach threshold

% For getLicks.m
settings.lick.maxReachFrequency=20; % in Hz, the maximum frequency at which mouse can reach
settings.lick.reachThresh=1; % after non-parametric Z score transformation of reachData, threshold for determining mouse reach
settings.lick.holdThreshold=5; % in seconds -- if any reach lasts longer than 10 s, this is not a reach -- this is a hold
settings.lick.plotOutput=1; % if 1, plot output of reach analysis, else do not plot

% For getPelletInPlace.m
settings.pellet.userDefinedThresh=1; % set to 1 if want user to manually define threshold for pellet present, instead of automated method
if exist('doManual','var')
    if doManual==true
        settings.pellet.userDefinedThresh=1;
    end
end
settings.pellet.subtractReachZone=0; % set to 1 if mouse tends to leave paw on wheel in pellet zone
% settings.pellet.nScaledMAD=3; % how many scaled median absolute deviations away from median for data point to be called an outlier
settings.pellet.nScaledMAD=1.75; % how many scaled median absolute deviations away from median for data point to be called an outlier
settings.pellet.plotOutput=1; % if 1, plot output, else do not plot
settings.pellet.pelletAboveFractionOfRange=0.75;
settings.pellet.useNewPelletApproach=true; % if want to use gaussian mixture model to detect pellet present, this is the newer approach
settings.pellet.zeroDerivRange=[-1000 1000]; % this should be fairly consistent across videos acquired by same camera, assuming pellet size does not change
% zeroDerivRange is range to call "zero" derivative in pellets.rawData

% For getChewing.m
settings.chew.added_path='C:\Users\sabatini\Documents\GitHub\chronux_2_11'; % path to Chronux
if exist('chronPath','var')
    if ~isempty(chronPath)
        settings.chew.added_path=chronPath;
    end
end
% settings.chew.chewFrequency=[4 6]; % frequency range at which mouse chews in Hz
settings.chew.chewFrequency=[5.5 7.7]; % frequency range at which mouse chews in Hz
settings.chew.chewingThresh=0.25; % in non-parametric Z score metrics, threshold for power in chewing frequency range above which mouse is chewing
if exist('chewThresh','var')
    if ~isempty(chewThresh)
        settings.chew.chewingThresh=chewThresh;
    end
end
% settings.chew.chewingThresh=0.9; % for lick expt: in non-parametric Z score metrics, threshold for power in chewing frequency range above which mouse is chewing
% settings.chew.tapers=[10 12]; % Chronux mtspecgramc tapers to use for identifying chewing at chewFrequency
settings.chew.tapers=[5 7]; % Chronux mtspecgramc tapers to use for identifying chewing at chewFrequency
settings.chew.fpass=[2 15]; % in Hz, the range for Chronux mtspecgramc
% settings.chew.chewingWindow=[7 1]; % in seconds, first element: window for Chronux mtspecgramc to use to calculate power at chewing frequency
%                                    % in seconds, second element: step for Chronux mtspecgramc to use to slide window across data
settings.chew.chewingWindow=[5 0.25]; % in seconds, first element: window for Chronux mtspecgramc to use to calculate power at chewing frequency
                                   % in seconds, second element: step for Chronux mtspecgramc to use to slide window across data
settings.chew.plotOutput=1; % if 1, plot output, else do not plot
% settings.chew.minTimeToChewPellet=6; % in seconds, the minimum time it takes mouse to eat pellet (e.g., vs chewing Ensure)
settings.chew.minTimeToChewPellet=3;
settings.chew.withinXSeconds=20; % must be at least minTimeToChewPellet seconds of chewing withinXSeconds for bout to be classified as chewing pellet
settings.chew.dropIfChewingBefore=1; % if 1, will classify a reach as a drop, instead of a success, 
% if mouse was chewing prior to reach (i.e., still consuming previous pellet) within priorToReach_chewWindow seconds
% AND chew time following reach is less than minTimeToChew_afterReach
settings.chew.minTimeToChew_afterReach=6; % in seconds, a more stringent criterion for pellet consumption time, to disambiguate 
% continued chewing of previous pellet after failed reach from successful reach
settings.chew.priorToReach_chewWindow=4; % in seconds, window prior to reach to check for chewing
                                  
% Check whether chewing is actually grooming?
settings.checkForGrooming=0; % 1 if want user to do this check, 0 otherwise
settings.removeGroomingFromEating=0; % 1 if want grooming stretches to be removed as eating stretches, 0 otherwise

% For pawAtMouth.m
% settings.paw.pawAtMouthThresh=5; % in non-parametric Z score metrics, intensity threshold for determining when paw is raised to mouth
settings.paw.pawAtMouthThresh=1.5; % for lick expt: in non-parametric Z score metrics, intensity threshold for determining when paw is raised to mouth
settings.paw.maxPawAtMouthFreq=5; % in Hz, the maximum frequency at which mouse can repeatedly raise paw to mouth
settings.paw.plotOutput=1; % if 1, plot output, else do not plot 

% For getFidget.m
settings.fidget.perchThresh=2; % after non-parametric transformation of perchData
settings.fidget.plotOutput=1; % if 1, plot output, else do not plot 

% For codeEvents.m
settings.pelletSettledForTime=0.066; % time in seconds for pellet to be at proper reach position, before reach begins
settings.fromPerchWindow=0.5; % in seconds, how long the paw must be at perch (i.e., not reaching) before reach, for reach to count as beginning from perch
% Reach type code
settings.missType=1;
settings.grabType=2; % note that grab type should always be overwritten as either eatType or dropType
settings.eatType=3;
settings.dropType=4;
settings.timeFromReachToMouth=1; % in seconds, reach is only "successful" if paw is raised to mouth within this time window
settings.timeFromReachToChew=7; % in seconds, reach is only "succesful" if chewing within this time window, note that min ITI is 9 seconds, given loader wheel
% 8 to 9 seconds is best for licking and reaching expt, but used 4 seconds
% for reaching alone