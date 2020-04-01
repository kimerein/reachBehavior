function out=getPawAtMouth(eatData)

% user-defined settings
settings=autoReachAnalysisSettings();
pawAtMouthThresh=settings.paw.pawAtMouthThresh;
maxPawAtMouthFreq=settings.paw.maxPawAtMouthFreq; 
movie_fps=settings.movie_fps; 
plotOutput=settings.paw.plotOutput; 


minRaisePeriod=1/maxPawAtMouthFreq; % in seconds
movieFramePeriod=1/movie_fps; % in seconds
minIndsBetweenMouth=floor(minRaisePeriod/movieFramePeriod);

% Find times when mouse raises paw/pellet to mouth
eatZoneData=nonparamZscore(eatData); % non-parametric Z score
isPawAtMouth=single(eatZoneData>pawAtMouthThresh);

% Find peaks
[~,raisePeakLocs,raiseWidths]=findpeaks(eatZoneData,'MinPeakDistance',minIndsBetweenMouth,'MinPeakHeight',pawAtMouthThresh,'WidthReference','halfheight');
raisePeaks=zeros(size(eatZoneData));
raisePeaks(raisePeakLocs)=1;
currRaiseWidth=zeros(size(eatZoneData));
currRaiseWidth(raisePeakLocs)=raiseWidths;

% Map nans
isPawAtMouth(isnan(eatData)==1)=nan;
raisePeaks(isnan(eatData)==1)=nan;
currRaiseWidth(isnan(eatData)==1)=nan;

out.isPawAtMouth=isPawAtMouth;
out.raisePeaks=raisePeaks;
out.currRaiseWidth=currRaiseWidth;

if plotOutput==1
   f=figure(); 
   plot(eatZoneData);
   hold on;
   plot(out.isPawAtMouth.*max(eatZoneData),'Color','r');
   plot(out.raisePeaks.*max(eatZoneData),'Color','k');
   leg={'z-scored eat zone intensity','paw at mouth','peak time of paw at mouth'};
   title('Paw At Mouth Classification');
   legend(leg);
   if settings.isOrchestra==1
       out.fig=f;
   end
end