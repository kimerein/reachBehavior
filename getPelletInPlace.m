function out=getPelletInPlace(pelletData)

out.rawData=pelletData;

% use the data as an indicator of how well-positioned the
% pellet is at each time

% user-defined settings
settings=autoReachAnalysisSettings();
userDefine=settings.pellet.userDefinedThresh; % 1 if user manually defines threshold for pellet present, instead of automated method
nScaledMAD=settings.pellet.nScaledMAD; % how many scaled median absolute deviations away from median for data point to be called an outlier
plotOutput=settings.pellet.plotOutput; % if 1, plot output, else do not plot

out.pelletPercRank=(tiedrank(pelletData)-1)./(length(pelletData)-1);

if userDefine==1
    figure(); 
    plot(pelletData);
    title('Raw pellet zone data');
    thresh=input('Enter threshold for pellet present detection. Values above this threshold indicate that pellet is present. ');
    pelletPresent=pelletData>thresh;
    pelletPresent=single(pelletPresent);
    pelletPresent(isnan(pelletData))=nan;
else
    [outlier,med,scaledMAD]=isoutlier(pelletData,nScaledMAD);
    pelletPresent=zeros(size(pelletData));
    pelletPresent(isnan(pelletData))=nan;
    pelletPresent(outlier==true)=1;
end
out.pelletPresent=pelletPresent;

if plotOutput==1
    f=figure();
    plot(pelletData,'Color','k');
    temp=pelletPresent;
    temp(temp==1)=nanmax(pelletData);
    temp(temp==0)=nanmin(pelletData);
    hold on;
    plot(temp,'Color','r');
    leg={'pellet zone intensity','pellet present'};
    title('Pellet Present Classification');
    legend(leg);
    if settings.isOrchestra==1
       out.fig=f;
   end
end

end

function [outlier,med,scaledMAD]=isoutlier(data,nScaledMAD)

c=-1/(sqrt(2)*erfcinv(3/2));
scaledMAD=c*nanmedian(abs(data-nanmedian(data)));

med=nanmedian(data);
outlier=(data>(nanmedian(data)+nScaledMAD*scaledMAD)) | (data<(nanmedian(data)-nScaledMAD*scaledMAD));

end