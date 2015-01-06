clc, clear

dataAnalysisFile = mfilename('fullpath')

workingDir = './RandomTestData_Mesh_SurfaceNoise_Outliers';
outputFolder = [];
% workingDir = '.';
% outputFolder = [];

% trial converged if GTErr_mean < convThresh
convThresh = 10;
maxIter = 100;

outliers = {'0.05','0.1','0.2','0.3'};

noisePerpPlane = {'0.5','1','2','1','2','2','0.5','1','0.5' };
noiseInPlane   = {'0.5','1','2','0.5','1','0.5','1','2','2' };

sampleSize = {'100'};
%sampleSize = {'100','75','50','35','20','10'};

minOffsetPos = {'15','30'};
maxOffsetPos = {'30','60'};
minOffsetAng = {'15','30'};
maxOffsetAng = {'30','60'};
outputSuffix = '';

algName = {
  'StdICP'
  'RobustICP'
  'IMLP'
  };

algOutlierSubNames = {
  repmat({''},1,size(outliers,2))
  repmat({''},1,size(outliers,2))
  {'_ChiSqu7.81','_ChiSqu6.25','_ChiSqu4.64','_ChiSqu3.66'}
  };

cmpAlgIndex = 1;  % compare other trials to IMLP

nAlgs = size(algName,1);
nOffsets = size(minOffsetPos,2);
nNoises = size(noiseInPlane,2);
nSampleSizes = size(sampleSize,2);
nOutliers = size(outliers,2);

%nTestsPerAlg = nOffsets*nNoises*nSampleSizes;

if (size(algName,1) ~= nAlgs)
  error('Size of algDir must match size of algName');
end

field_names = {...
  ... % arrays storing values of each trial
  'trials_TREAvg','trials_TRESD','trials_Rerr','trials_Terr','trials_Runtime',...
  'trials_runtimeFirstMatch','trials_NumIter',...
  ... % summary values for all trials in a test
  'cTRE_Avg','cTRE_SD',...
  'cRotErrAvg','cRotErrSD','cTransErrAvg','cTransErrSD',...
  'cRunTimeAvg','cNumIterAvg','cNumMaxIter','ncNumMaxIter',...
  'NumNonConv',...
  'cAvgOutliers','ncAvgOutliers'...
  };

% preallocate struct for storing data
empty_cells = repmat(cell(1),1,numel(field_names));
entries = {field_names{:}; empty_cells{:}};
myStruct = struct(entries{:});

% preallocate struct array
data = repmat(myStruct, nAlgs,nOffsets,nNoises);

% summary file for all tests performed
summaryFile = ['_SummaryPostAnalysis_Conv',int2str(convThresh),outputSuffix,'.txt'];
summaryFilePath = [workingDir,'/',outputFolder,'/',summaryFile];
fidSum = fopen(summaryFilePath,'w');
if fidSum == -1; error('Open file failure'); end;
fprintf(fidSum,'Summary results over all tests performed\n\n');
fprintf(fidSum,'NOTES:   convergence threshold = %d\n', convThresh);
fprintf(fidSum,'         GTE means \"Ground Truth Error\" of validation samples\n');
fprintf(fidSum,'         all values reported as (mean/SD)"\n\n');
fprintf(fidSum,'Format for Trial Results:\n');
fprintf(fidSum,'%24s AngErr\t\t\tPosErr\t\t\t\tRuntime\t\t\t\tGTE\t\t\t\tNumIter\t\tNonConv\tNumMaxIter\tNumMaxIterNonConv\tnTrials\tAvgOutliers (Conv NonConv)\n\n',' ');

for offset = 1:nOffsets
  for noise = 1:nNoises
    for outlier = 1:nOutliers
      %for size = 1:nSampleSizes
      
      testName = ['Noise_Prll',noiseInPlane{noise},'Perp',noisePerpPlane{noise},...
        '_Offset_R',minOffsetAng{offset},'-',maxOffsetAng{offset},'T',minOffsetPos{offset},'-',maxOffsetPos{offset}, ...
        '_Outliers',outliers{outlier},...
        ]; %'_NSamps',sampleSize{size}]
      
      %resultsFile = ['_PostAnalysis_',testName,'_Conv',int2str(convThresh),outputSuffix,'.txt'];
      resultsFile = ['_PostAnalysis_',testName,'_Conv',int2str(convThresh),'.txt'];
      resultsFilePath = [workingDir,'/',outputFolder,'/',resultsFile];
      fidres = fopen(resultsFilePath,'w');
      if fidres == -1; error('Open file failure'); end;
      
      % Results File for this Test Case
      fprintf(fidres,'Summary results for each trial type\n\n');
      fprintf(fidres,'NOTES:   convergence threshold = %d\n', convThresh);
      fprintf(fidres,'         GTE means \"Ground Truth Error\"\n');
      fprintf(fidres,'         values reported as (mean/SD)"\n\n');
      
      % Summary File
      fprintf(fidSum,'\n%s\n', testName);
      
      for alg = 1:nAlgs
        
        algFullName = [algName{alg},algOutlierSubNames{alg}{outlier}];
        trialDir = [workingDir,'/',algFullName,'/',testName]
        
        % Stats File Format:
        %  (format for one line, with each line representing a single trial within a randomized test case)
        %
        %  GTPos_mean   GTPos_SD ...
        %  Rerr         Terr ...
        %  runtime      timeFirstIter...
        %  numIter      nOutliers (optional)
        %        
        statsfile = [trialDir,'/','stats_',algFullName,'.txt']
        stats = textread(statsfile);
        nTrials = size(stats,1);
        if size(stats,2) < 8
          stats(:,8) = -ones(nTrials,1);
        end
        
        
        % identify converged trials
        % (by mean ground truth position error of validation samples)
        convTrials = stats(:,1)<=convThresh;
        convStats = stats(convTrials,:);
        nonConvStats = stats(~convTrials,:);
        nTrialsConv = size(convStats,1);
        nTrialsNonConv = size(nonConvStats,1);
        
        %-- Converged Stats --%
        % ground truth position error
        cGTErr_mean = sum(convStats(:,1))/nTrialsConv;
        cGTErr_Var = sum(convStats(:,2).^2)/nTrialsConv;
        cGTErr_SD = sqrt(cGTErr_Var);
        % ground truth transform error
        cAngErr_mean = sum(convStats(:,3))/nTrialsConv;
        cPosErr_mean = sum(convStats(:,4))/nTrialsConv;
        cRunTime_mean = sum(convStats(:,5))/nTrialsConv;
        cRunTimeFirstMatch_mean = sum(convStats(:,6))/nTrialsConv;
        cNumIter_mean = sum(convStats(:,7))/nTrialsConv;
        cAngErr_SD = sqrt(sum((convStats(:,3)-cAngErr_mean).^2)/nTrialsConv);
        cPosErr_SD = sqrt(sum((convStats(:,4)-cPosErr_mean).^2)/nTrialsConv);
        cRunTime_SD = sqrt(sum((convStats(:,5)-cRunTime_mean).^2)/nTrialsConv);
        cRunTimeFirstMatch_SD = sqrt(sum((convStats(:,6)-cRunTimeFirstMatch_mean).^2)/nTrialsConv);
        cNumIter_SD = sqrt(sum((convStats(:,7)-cNumIter_mean).^2)/nTrialsConv);
        cNumMaxIter = sum(convStats(:,7)==maxIter);
        cAvgOutliers = mean(convStats(:,8));
        
        %-- NonConverged Stats --%
        if (nTrialsNonConv == 0)
          ncGTErr_mean = 0;
          ncGTErr_Var = 0;
          ncGTErr_SD = 0;
          ncAngErr_mean = 0;
          ncPosErr_mean = 0;
          ncRunTime_mean = 0;
          ncRunTimeFirstMatch_mean = 0;
          ncNumIter_mean = 0;
          ncAngErr_SD = 0;
          ncPosErr_SD = 0;
          ncRunTime_SD = 0;
          ncRunTimeFirstMatch_SD = 0;
          ncNumIter_SD = 0;
          ncNumMaxIter = 0;
          ncAvgOutliers = 0;
        else
          ncGTErr_mean = sum(nonConvStats(:,1))/nTrialsNonConv;
          ncGTErr_Var = sum(nonConvStats(:,2).^2)/nTrialsNonConv;
          ncGTErr_SD = sqrt(ncGTErr_Var);
          ncAngErr_mean = sum(nonConvStats(:,3))/nTrialsNonConv;
          ncPosErr_mean = sum(nonConvStats(:,4))/nTrialsNonConv;
          ncRunTime_mean = sum(nonConvStats(:,5))/nTrialsNonConv;
          ncRunTimeFirstMatch_mean = sum(nonConvStats(:,6))/nTrialsNonConv;
          ncNumIter_mean = sum(nonConvStats(:,7))/nTrialsNonConv;
          ncAngErr_SD = sqrt(sum((nonConvStats(:,3)-ncAngErr_mean).^2)/nTrialsNonConv);
          ncPosErr_SD = sqrt(sum((nonConvStats(:,4)-ncPosErr_mean).^2)/nTrialsNonConv);
          ncRunTime_SD = sqrt(sum((nonConvStats(:,5)-ncRunTime_mean).^2)/nTrialsNonConv);
          ncRunTimeFirstMatch_SD = sqrt(sum((nonConvStats(:,6)-ncRunTimeFirstMatch_mean).^2)/nTrialsNonConv);
          ncNumIter_SD = sqrt(sum((nonConvStats(:,7)-ncNumIter_mean).^2)/nTrialsNonConv);
          ncNumMaxIter = sum(nonConvStats(:,7)==maxIter);
          ncAvgOutliers = mean(nonConvStats(:,8));
        end
        
        % Write Results to File
        fprintf(fidres,'Results for Trials:   %s\n\n',algFullName);
        fprintf(fidres,' Convergence Rate:          %.3f\n', nTrialsConv/nTrials);
        fprintf(fidres,' Num trials converged:      %u\n', nTrialsConv);
        fprintf(fidres,' Num trials not converged:  %u\n', nTrialsNonConv);
        fprintf(fidres,' Num trials total:          %u\n\n', nTrials);
        fprintf(fidres,' Converged:\n');
        fprintf(fidres,'   GTE_Pos:   %.2f/%.2f\n', cGTErr_mean,cGTErr_SD);
        fprintf(fidres,'   AngErr:    %.2f/%.2f\n', cAngErr_mean,cAngErr_SD);
        fprintf(fidres,'   PosErr:    %.2f/%.2f\n', cPosErr_mean,cPosErr_SD);
        fprintf(fidres,'   RunTime:   %.2f/%.2f\n', cRunTime_mean,cRunTime_SD);
        fprintf(fidres,'   1stIter:   %.2f/%.2f\n', cRunTimeFirstMatch_mean,cRunTimeFirstMatch_SD);
        fprintf(fidres,'   NumIter:   %.2f/%.2f\n', cNumIter_mean,cNumIter_SD);
        fprintf(fidres,'   NumMaxIter:  %u\n', cNumMaxIter);
        fprintf(fidres,'   AvgOutliers: %u\n\n', cAvgOutliers);
        fprintf(fidres,' Non Converged:\n');
        fprintf(fidres,'   GTE_Pos:   %.2f/%.2f\n', ncGTErr_mean,ncGTErr_SD);
        fprintf(fidres,'   AngErr:    %.2f/%.2f\n', ncAngErr_mean,ncAngErr_SD);
        fprintf(fidres,'   PosErr:    %.2f/%.2f\n', ncPosErr_mean,ncPosErr_SD);
        fprintf(fidres,'   RunTime:   %.3f/%.3f\n', ncRunTime_mean,ncRunTime_SD);
        fprintf(fidres,'   1stMatch:  %.3f/%.3f\n', ncRunTimeFirstMatch_mean,ncRunTimeFirstMatch_SD);
        fprintf(fidres,'   NumIter:   %.2f/%.2f\n', ncNumIter_mean,ncNumIter_SD);
        fprintf(fidres,'   NumMaxIter:  %.2f\n', ncNumMaxIter);
        fprintf(fidres,'   AvgOutliers: %.2f\n\n', ncAvgOutliers);
        
        % Summary file
        %  left justify and pad the alg name with spaces to achieve data alignment
        fprintf(fidSum,'%-20s:\t\t%.2f/%.2f  %.2f/%.2f   %6.3f/%.3f   %.2f/%.2f   %4.1f/%-4.1f   %3u    %3u    %3u    (numTrials = %u)  %.1f %.1f\n',...
          algFullName, cAngErr_mean,cAngErr_SD, cPosErr_mean,cPosErr_SD, ...
          cRunTime_mean,cRunTime_SD, cGTErr_mean,cGTErr_SD, ...
          cNumIter_mean, cNumIter_SD, nTrialsNonConv, cNumMaxIter, ncNumMaxIter, nTrials, cAvgOutliers, ncAvgOutliers);
        
        % arrays storing values of each trial
        dataDescription = 'data(alg,offset,noise).field_name';
        data(alg,offset,noise,outlier).trials_TREAvg = stats(:,1);
        data(alg,offset,noise,outlier).trials_TRESD = stats(:,2);
        data(alg,offset,noise,outlier).trials_Rerr = stats(:,3);
        data(alg,offset,noise,outlier).trials_Terr = stats(:,4);
        data(alg,offset,noise,outlier).trials_Runtime = stats(:,5);
        data(alg,offset,noise,outlier).trials_runtimeFirstMatch = stats(:,6);
        data(alg,offset,noise,outlier).trials_NumIter = stats(:,7);
        % summary values for all trials in a test
        data(alg,offset,noise,outlier).cTRE_Avg = cGTErr_mean;
        data(alg,offset,noise,outlier).cTRE_SD = cGTErr_SD;
        data(alg,offset,noise,outlier).cRotErrAvg = cAngErr_mean;
        data(alg,offset,noise,outlier).cRotErrSD = cAngErr_SD;
        data(alg,offset,noise,outlier).cTransErrAvg = cPosErr_mean;
        data(alg,offset,noise,outlier).cTransErrSD = cPosErr_SD;
        data(alg,offset,noise,outlier).cRunTimeAvg = cRunTime_mean;
        data(alg,offset,noise,outlier).cNumIterAvg = cNumIter_mean;
        data(alg,offset,noise,outlier).cNumMaxIter = cNumMaxIter;
        data(alg,offset,noise,outlier).ncNumMaxIter = ncNumMaxIter;
        data(alg,offset,noise,outlier).NumNonConv = nTrialsNonConv;
        data(alg,offset,noise,outlier).cAvgOutliers = cAvgOutliers;
        data(alg,offset,noise,outlier).ncAvgOuttiers = ncAvgOutliers;
        
      end % 1:nAlg
      
      % algorithm comparison
      i = cmpAlgIndex;
      cmpAlgFullName = [algName{cmpAlgIndex},algOutlierSubNames{cmpAlgIndex}{outlier}];
      fprintf(fidres,'\n\n\nConvergence comparison with %s\n\n', cmpAlgFullName);
      trialDir = [workingDir,'/',cmpAlgFullName,'/',testName]
      statsfile = [trialDir,'/','stats_',cmpAlgFullName,'.txt']
      stats = textread(statsfile);
      cCmpAlg = stats(:,1)<=convThresh; % convergence for cmpAlg
      for i=1:nAlgs
        if i == cmpAlgIndex; continue; end;
        algFullName = [algName{i},algOutlierSubNames{i}{outlier}];
        trialDir = [workingDir,'/',algFullName,'/',testName]
        statsfile = [trialDir,'/','stats_',algFullName,'.txt']
        stats = textread(statsfile);
        % may not have run as many trials for this method
        nTrials = size(stats,1);
        % convergence for other method
        cOther = stats(:,1)<=convThresh;
        % cmpAlg converges; Other does not converge
        %betterCmp = (cCmpAlg==1) && (cOther==0);
        betterCmp = cCmpAlg(1:nTrials).*~cOther;
        betterCmpTrials = find(betterCmp==1);
        % ICP does not converge; Other method converges
        %betterOther = (cCmpAlg==0)&&(cOther==1);
        betterOther = ~cCmpAlg(1:nTrials).*cOther;
        betterOtherTrials = find(betterOther==1);
        % both diverge
        bothDiv = ~cCmpAlg(1:nTrials).*~cOther;
        bothDivTrials = find(bothDiv==1);
        fprintf(fidres,'%s vs %s\n',cmpAlgFullName,algFullName);
        fprintf(fidres,' %s converged;  %s diverged\n',cmpAlgFullName,algFullName);
        fprintf(fidres,'   %u\n', betterCmpTrials);
        fprintf(fidres,' %s diverged;   %s converged\n',cmpAlgFullName,algFullName);
        fprintf(fidres,'   %u\n', betterOtherTrials);
        fprintf(fidres,' Both diverged\n');
        fprintf(fidres,'   %u\n', bothDivTrials);
        fprintf(fidres,'\n\n');
      end
      
      % total non-converged trials for each algorithm
      for i=1:nAlgs
        algFullName = [algName{i},algOutlierSubNames{i}{outlier}];
        trialDir = [workingDir,'/',algFullName,'/',testName]
        statsfile = [trialDir,'/','stats_',algFullName,'.txt']
        stats = textread(statsfile);
        % may not have run as many trials for this method
        nTrials = size(stats,1);
        % find non-convergence trials for this algorithm
        converged = stats(:,1)<=convThresh;
        diverged = ~converged;
        divTrials = find(diverged==1);
        fprintf(fidres,'All non-convergence trials for: %s\n',algFullName);
        fprintf(fidres,'   %u\n', divTrials);
        fprintf(fidres,'\n\n');
      end
      
      fclose( fidres );
      
    end
  end
end

fclose( fidSum );


% Save Analysis
disp('Saving Workspace Data');
workspaceFile = [workingDir,'/','SaveAnalysisWorkspace.mat'];
save(workspaceFile);
dataFile = [workingDir,'/','SaveAnalysisData.mat'];
save(dataFile,...
  'data','dataAnalysisFile',...
  'dataDescription','nAlgs','nOffsets','nNoises','nSampleSizes','nOutliers',...
  'algName','sampleSize','outliers',...
  'minOffsetPos','maxOffsetPos','minOffsetAng','maxOffsetAng',...
  'noiseInPlane','noisePerpPlane',...
  'convThresh','maxIter')

disp('All Analysis Complete');

