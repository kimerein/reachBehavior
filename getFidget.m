function out=getFidget(perchData)

% user-defined settings
settings=autoReachAnalysisSettings();
fidgetThresh=settings.fidget.perchThresh; 
plotOutput=settings.fidget.plotOutput;

fidgeting=nonparamZscore(abs(diff([perchData perchData(end)])));
fidgeting(isnan(perchData))=nan;

out.isFidgeting=single(fidgeting>fidgetThresh);
out.isFidgeting(isnan(perchData))=nan;
out.fidgetData=fidgeting;

if plotOutput==1
   f=figure(); 
   plot(fidgeting,'Color','k');
   hold on;
   plot(out.isFidgeting.*max(fidgeting),'Color','r');
   leg={'temporal derivative of perch zone intensity','is fidgeting'};
   title('Fidget Classification');
   legend(leg);
   if settings.isOrchestra==1
       out.fig=f;
   end
end