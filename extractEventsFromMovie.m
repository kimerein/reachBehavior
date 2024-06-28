function [out,zoneVals,reaches,pellets,eat,paw,fidget,settings]=extractEventsFromMovie(zonesFile, movieFile, zoneVals)

settings=autoReachAnalysisSettings(); % get current settings for this analysis
settings.zonesFile=zonesFile;
settings.movieFile=movieFile; 

% Read intensity in user-defined zones over course of movie
if isempty(zoneVals)
    zoneVals=readIntensityValues(zonesFile, movieFile);
    readZoneVals=1;
else
    readZoneVals=0;
end

% Save zone data
if settings.saveZoneData==1 && readZoneVals==1
    endoffname=regexp(movieFile,'\.');
    save([movieFile(1:endoffname(end)-1) '_zoneVals.mat'],'zoneVals');
end

% Save analysis settings
if settings.saveZoneData==1
    endoffname=regexp(movieFile,'\.');
    save([movieFile(1:endoffname(end)-1) '_settings.mat'],'settings');
end

% Discard first n frames
f=fieldnames(zoneVals);
for i=1:length(f)
    temp=zoneVals.(f{i});
    zoneVals.(f{i})=temp(settings.discardFirstNFrames+1:end);
end

% Check for unusual correlations between zones -- could indicate a problem
% with the user-entered zones
% The zones should be independent

% Fixing a noise issue that existed for a few days
if settings.fixUnderpoweredDVR==true
    % use optoZone to correct noise in reachZone
    % user must have known to draw optoZone at the correct spot in video
    % for this to work
    % generally, this correction is not necessary

    % open zones definition to figure out relative sizes of reach and opto
    % zones
%     a=load(zonesFile);
%     sizeOptoZone=1;
%     sizeReachZone=1;
%     for i=1:length(a.zones)
%         currName=a.zones(i).name;
%         if strcmp(a.zones(i).name,'opto zone')
%             sizeOptoZone=nansum(a.zones(i).isin==1);
%         elseif strcmp(a.zones(i).name,'reach zone')
%             sizeReachZone=nansum(a.zones(i).isin==1);
%         end
%     end
%     scaleFac=sizeReachZone/sizeOptoZone;

%     figure(); 
%     plot(zoneVals.reachZone-nanmin(zoneVals.reachZone),'Color','k'); 
%     hold on; 
%     plot(zoneVals.optoZone-nanmin(zoneVals.optoZone),'Color','r');
%     legend({'reach zone','opto zone'});
%     title('Correcting noise in video');
%     zoneVals.reachZone=zoneVals.reachZone-nanmin(zoneVals.reachZone)-scaleFac*(zoneVals.optoZone-nanmin(zoneVals.optoZone));

    if settings.flipReachZone==true
        zoneVals.reachZone=-zoneVals.reachZone;
    end
    temp=isnan(zoneVals.reachZone);
    toTransform=zoneVals.reachZone;
    toTransform(temp)=0;
    toTransform=bandPassLFP(toTransform,30,0.1,0.3,0)';
    toTransform(temp)=nan;
    toTransform=toTransform';
    backup=zoneVals.reachZone;
    zoneVals.reachZone=(backup-median(backup,2,'omitnan'))-toTransform;
    zoneVals.reachZone(isnan(zoneVals.reachZone))=0;
    zoneVals.reachZone=bandPassLFP(zoneVals.reachZone,30,1,10000,0);
    zoneVals.reachZone(find(~isnan(zoneVals.reachZone),1,'last')-100:find(~isnan(zoneVals.reachZone),1,'last'))=median(zoneVals.reachZone,2,'omitnan');
    figure();
    plot(zoneVals.reachZone,'Color','k');
    title('Fixed reach zone');

    % Filter LED zone to get rid of low-frequency noise at approx. 0.2 Hz
    temp=isnan(zoneVals.LEDZone);
    zoneVals.LEDZone(temp)=0;
    zoneVals.LEDZone=bandPassLFP(zoneVals.LEDZone,30,0.3,10000,0)';
    zoneVals.LEDZone(temp)=nan;
    zoneVals.LEDZone=zoneVals.LEDZone';
    zoneVals.LEDZone(find(~isnan(zoneVals.LEDZone),1,'last')-100:find(~isnan(zoneVals.LEDZone),1,'last'))=median(zoneVals.LEDZone,2,'omitnan');
    figure();
    plot(zoneVals.LEDZone);
    title('Fixed LED zone');
    
    % Filter cue zone to get rid of low-frequency noise at approx. 0.2 Hz
    temp=isnan(zoneVals.cueZone);
    zoneVals.cueZone(temp)=0;
    zoneVals.cueZone=bandPassLFP(zoneVals.cueZone,30,0.3,10000,0)';
    zoneVals.cueZone(temp)=nan;
    zoneVals.cueZone=zoneVals.cueZone';
    zoneVals.cueZone(find(~isnan(zoneVals.cueZone),1,'last')-100:find(~isnan(zoneVals.cueZone),1,'last'))=median(zoneVals.cueZone,2,'omitnan');
    figure();
    plot(zoneVals.cueZone,'Color','b');
    title('Fixed cue zone');
end

% Get reach data
reaches=getReaches(zoneVals.reachZone);

% Get pellet data
if settings.pellet.subtractReachZone==1
    zoneVals=subtractReachFromPelletZones(zoneVals);
end
if settings.pellet.useNewPelletApproach==true
    pellets.rawData=zoneVals.pelletZone;
    pellets=pelletPresentByDerivZero(pellets,settings.pellet.zeroDerivRange,settings.isOrchestra);
else
    pellets=getPelletInPlace(zoneVals.pelletZone);
end

% Get chewing data
eat=getChewing(zoneVals.eatZone);

% Get paw at mouth data
paw=getPawAtMouth(zoneVals.eatZone);

% Get fidgeting in perch zone data
fidget=getFidget(zoneVals.perchZone);

% Get licking
if isfield(zoneVals,'lickZone')
    licks=getLicks(zoneVals.lickZone);
    eat.licks=licks;
end

% Remove "eating" classification while mouse is licking
% eat=removeLicksFromEat(eat);

% Check if mouse is grooming
if settings.checkForGrooming==1
    eat=checkForGrooming(eat,settings);
    pause;
end

[~,out]=codeEvents(reaches,pellets,eat,paw,fidget); 

% Save output
if settings.isOrchestra==1
    % save figures
    endoffname=regexp(movieFile,'\.');
    savefig(reaches.fig,[movieFile(1:endoffname(end)-1) '_reachesFig.fig'],'compact');
    savefig(pellets.fig,[movieFile(1:endoffname(end)-1) '_pelletsFig.fig'],'compact');
    savefig(eat.fig1,[movieFile(1:endoffname(end)-1) '_eatFig1.fig'],'compact');
    savefig(eat.fig2,[movieFile(1:endoffname(end)-1) '_eatFig2.fig'],'compact');
    savefig(paw.fig,[movieFile(1:endoffname(end)-1) '_pawFig.fig'],'compact');
    savefig(fidget.fig,[movieFile(1:endoffname(end)-1) '_fidgetFig.fig'],'compact');   
    close all
    reaches.fig=[];
    pellets.fig=[];
    eat.fig=[];
    paw.fig=[];
    fidget.fig=[];
end
if settings.saveZoneData==1
    endoffname=regexp(movieFile,'\.');
    save([movieFile(1:endoffname(end)-1) '_events.mat'],'out');
    save([movieFile(1:endoffname(end)-1) '_reaches.mat'],'reaches');
    save([movieFile(1:endoffname(end)-1) '_pellets.mat'],'pellets');
    save([movieFile(1:endoffname(end)-1) '_eat.mat'],'eat');
    save([movieFile(1:endoffname(end)-1) '_paw.mat'],'paw');
    save([movieFile(1:endoffname(end)-1) '_fidget.mat'],'fidget');
end

end

function zoneVals=subtractReachFromPelletZones(zoneVals)

zoneVals.pelletZone=zoneVals.pelletZone-prctile(zoneVals.pelletZone,5);
zoneVals.pelletZone=zoneVals.pelletZone./prctile(zoneVals.pelletZone,95);
zoneVals.reachZone=zoneVals.reachZone-prctile(zoneVals.reachZone,5);
zoneVals.reachZone=zoneVals.reachZone./prctile(zoneVals.reachZone,95);
backup=zoneVals.pelletZone;
figure();
plot(zoneVals.pelletZone,'Color','b');
hold on;
plot(zoneVals.reachZone,'Color','r');
zoneVals.pelletZone=zoneVals.pelletZone-zoneVals.reachZone;
zoneVals.pelletZone=zoneVals.pelletZone-prctile(zoneVals.pelletZone,5);
zoneVals.pelletZone=zoneVals.pelletZone./prctile(zoneVals.pelletZone,95);
plot(zoneVals.pelletZone,'Color','k');
leg={'pellet zone','reach zone','subtraction'};
title('Subtracting reach zone from pellet zone');
legend(leg);

figure(); 
plot(zoneVals.pelletZone,'Color','k');
title('Subtracting reach zone from pellet zone');

end