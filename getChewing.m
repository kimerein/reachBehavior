function out=getChewing(eatData)

% Note that isChewing only returns 1 for long bouts of chewing consistent with
% pellet consumption, usually ignoring short bouts of vacuous chewing

% Add path to Chronux
% user-defined settings
settings=autoReachAnalysisSettings();
added_path=settings.chew.added_path;
addpath(genpath(added_path));

movie_fps=settings.movie_fps;
chewFrequency=settings.chew.chewFrequency;
chewingThresh=settings.chew.chewingThresh;
chewingWindow=settings.chew.chewingWindow;
plotOutput=settings.chew.plotOutput;

params.Fs=settings.movie_fps;
params.tapers=settings.chew.tapers;
params.fpass=settings.chew.fpass; % in Hz

[S,t,f]=mtspecgramc(eatData(~isnan(eatData)),chewingWindow,params);
chewingpower=nanmean(S(:,f>=chewFrequency(1) & f<=chewFrequency(2)),2);
chewingpower=nonparamZscore(chewingpower);

frameTimes=0:(1/movie_fps):(length(eatData(~isnan(eatData)))-1)*(1/movie_fps);
chewingInFrames=mapToFrames(chewingpower,t,frameTimes);

out.isChewing=eatData;
out.isChewing(~isnan(eatData))=chewingInFrames>chewingThresh;
out.chewingInFrames=eatData;
out.chewingInFrames(~isnan(eatData))=chewingInFrames;
out.chewingpower=chewingpower;

% Remove path to Chronux
rmpath(genpath(added_path));

if plotOutput==1
   f(1)=figure(); 
   plot(settings.discardFirstNFrames:settings.discardFirstNFrames+length(out.chewingInFrames)-1,out.chewingInFrames,'Color','k');
   hold on;
   line([settings.discardFirstNFrames settings.discardFirstNFrames+length(out.chewingInFrames)-1],[chewingThresh chewingThresh],'Color','r');
   title('Threshold for chewing classification');
   if settings.isOrchestra~=1
       pause;
   end
    
   f(2)=figure();
   plot(eatData,'Color','k');
   temp=zeros(size(eatData));
   temp(isnan(eatData))=nan;
   temp(out.isChewing==true)=1;
   temp(temp==1)=max(eatData);
   temp(temp==0)=min(eatData);
   hold on; 
   plot(temp,'Color','r');
   temp=(chewingInFrames-min(chewingInFrames))./max(chewingInFrames); % scaled from 0 to 1
   temp=temp.*(max(eatData)-min(eatData));
   temp=temp+min(eatData);
   plot(temp,'Color','g');
   leg={'eat zone intensity','is chewing','chewing power'};
   title('Chewing Classification');
   legend(leg);
   if settings.isOrchestra==1
       out.fig1=f(1);
       out.fig2=f(2);
   end
end

end

function dataByFrames=mapToFrames(data,times,frameTimes)

dataByFrames=nan(size(frameTimes));

for i=1:length(times)
    [~,mi]=min(abs(times(i)-frameTimes));
    dataByFrames(mi)=data(i);
end

dataByFrames=fillInNans(dataByFrames);

end

function data=fillInNans(data)

inds=find(~isnan(data));
for i=1:length(inds)
    currind=inds(i);
    if i==1
        % fill in before
        data(1:currind-1)=data(currind);
    elseif i==length(inds)
        halfLength=floor((currind-inds(i-1))/2);
        data(inds(i-1)+1:inds(i-1)+1+halfLength)=data(inds(i-1));
        data(inds(i-1)+2+halfLength:currind-1)=data(currind);
        % fill in after
        data(currind+1:end)=data(currind);
    else
        % fill in with recent
        halfLength=floor((currind-inds(i-1))/2);
        data(inds(i-1)+1:inds(i-1)+1+halfLength)=data(inds(i-1));
        data(inds(i-1)+2+halfLength:currind-1)=data(currind);
    end
end
if any(isnan(data))
    error('Failed to replace all nans');
end
        

end