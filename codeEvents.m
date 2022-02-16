function [reachTypes,out]=codeEvents(reaches,pelletInPlace,eat,pawMouth,fidget)

% Event types
% Reach, but no pellet available
% Reach, but reach does not begin from perch
% Miss: reach but pellet does not move
% Grab: reach and pellet moves
% Eat: grab and paws at mouth
% Drop: grab but no paws at mouth

% Note that "drops" while the wheel turns are more likely "misses" -- but
% will need to fix this after alignment to Arduino data

% user-defined settings
settings=autoReachAnalysisSettings();
pelletSettledForTime=settings.pelletSettledForTime; % time in seconds for pellet to be at proper reach position, before reach begins
movie_fps=settings.movie_fps; % movie frame rate in frames per second
fromPerchWindow=settings.fromPerchWindow; % in seconds, how long the paw must be at perch (i.e., not reaching) before reach, for reach to count as beginning from perch
% Reach type code
missType=settings.missType;
grabType=settings.grabType; % note that grab type should always be overwritten as either eatType or dropType
eatType=settings.eatType;
dropType=settings.dropType;
timeFromReachToMouth=settings.timeFromReachToMouth; % in seconds, reach is only "successful" if paw is raised to mouth within this time window
timeFromReachToChew=settings.timeFromReachToChew; % in seconds, reach is only "succesful" if chewing within this time window

% For each reach, determine what type of reach it is

pelletSettledForInds=ceil(pelletSettledForTime/(1/movie_fps));
fromPerchInds=ceil(fromPerchWindow/(1/movie_fps));
reachToMouthInds=ceil(timeFromReachToMouth/(1/movie_fps));
reachToChewInds=ceil(timeFromReachToChew/(1/movie_fps));

reachInds=reaches.firstReachInds;
reachBegins=reaches.reachBegins;
reachEnds=reaches.reachEnds;

reachTypes=nan(1,length(reachInds));
pelletThere=nan(1,length(reachInds));
reachFromPerch=nan(1,length(reachInds));
raisedPaw=nan(1,length(reachInds));
atePellet=nan(1,length(reachInds));
for i=1:length(reachInds)
    if (reachBegins(i)-1<1) || (reachEnds(i)+1>length(pelletInPlace.pelletPresent))
        % reach is at beginning or end, skip
        continue
    end
    
    % Is a pellet available before this reach begins?
    if reachBegins(i)-pelletSettledForInds-1<1
        if all(pelletInPlace.pelletPresent(1:reachBegins(i)-1)==1)
            % yes
            pelletThere(i)=1;
        else
            % no
            pelletThere(i)=0;
        end
    elseif all(pelletInPlace.pelletPresent(reachBegins(i)-pelletSettledForInds-1:reachBegins(i)-1)==1)
        % yes
        pelletThere(i)=1;
    else
        % no
        pelletThere(i)=0;
    end
    
    % Does reach begin from perch?
    if reachBegins(i)-fromPerchInds-1<1
        if any(reaches.isReach(1:reachBegins(i)-1)==1)
            % no
            reachFromPerch(i)=0;
        else
            % yes
            reachFromPerch(i)=1;
        end
    elseif any(reaches.isReach(reachBegins(i)-fromPerchInds-1:reachBegins(i)-1)==1)
        % no
        reachFromPerch(i)=0;
    else
        % yes
        reachFromPerch(i)=1;
    end
    
    if (pelletThere(i)==0)
        continue
    end
    
    % Does mouse move the pellet? i.e., grab or miss
    % Is pellet gone at the end of the reach?
    if pelletInPlace.pelletPresent(reachEnds(i)+1)==1
        % mouse did not move pellet, so miss
        reachTypes(i)=missType;
    else
        % mouse did move pellet, so grab
        reachTypes(i)=grabType;
    end
    
    % Did mouse raise paw to mouth?
    if reachEnds(i)+reachToMouthInds>length(pawMouth.isPawAtMouth)
        if any(pawMouth.isPawAtMouth(reachEnds(i):end)==1)
            % yes
            raisedPaw(i)=1;
        else
            raisedPaw(i)=0;
        end
    elseif any(pawMouth.isPawAtMouth(reachEnds(i):reachEnds(i)+reachToMouthInds)==1)
        % yes
        raisedPaw(i)=1;
    else
        raisedPaw(i)=0;
    end
     
    % Did mouse eat after this reach?
    if reachEnds(i)+reachToChewInds>length(eat.isChewing)
        if any(eat.isChewing(reachEnds(i):end)==1)
            % yes
            atePellet(i)=1;
        else
            atePellet(i)=0;
        end
    elseif any(eat.isChewing(reachEnds(i):reachEnds(i)+reachToChewInds)==1)
        % yes
        atePellet(i)=1;
    else
        atePellet(i)=0;
    end
    
    % Successful eat or drop?
    if (reachTypes(i)==grabType) && (raisedPaw(i)==1) && (atePellet(i)==1)
        reachTypes(i)=eatType;      
    elseif (reachTypes(i)==grabType)
        reachTypes(i)=dropType;
    end
end

% For each reach, get the reach beginning based on perch zone fidgeting
% (rather than change in intensity in reach zone)
reachFidgetBegins=nan(size(reachBegins));
for i=1:length(reachInds)
    currBegin=reachBegins(i);
    for j=currBegin:-1:1
        % find beginning of this fidget
        if fidget.isFidgeting(j)==0
            break
        end
        reachFidgetBegins(i)=j;   
    end  
end
    
out.reachTypes=reachTypes;
out.pelletThere=pelletThere;
out.reachFromPerch=reachFromPerch;
out.raisedPaw=raisedPaw;
out.atePellet=atePellet;
out.reachFidgetBegins=reachFidgetBegins;

end