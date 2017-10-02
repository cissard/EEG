function [erp ntr] = computeERP(ind,epochs,vCut,nBadElectrodes,pre);

% remove bad trials
% make a matrix of bad electrodes per trial
badTrials = squeeze(any(epochs>vCut,2) | any(epochs<-vCut,2))';

% set number of bad electrodes to completely discount a trial
% if above this number, remove the trial completely; if below this
% number, just remove bad electrodes
for i = 1:size(badTrials,1)
    % if more bad electrodes than cutoff
    if sum(badTrials(i,:)) > nBadElectrodes
        % completely remove all electrodes on this trial
        trials2use(i,:) = zeros(1,11);
    else
        % otherwise, remove only bad electrodes
        trials2use(i,:) = ~ badTrials(i,:);
    end
end



% baseline correction (mean)
for i = 1:size(epochs,3)
    for ch = 1:11
        onset = round(pre*size(epochs,2));
        bcorr(ch,:,i) = epochs(ch,:,i) - mean(epochs(ch,1:onset,i));
    end
end

for ch = 1:11
    indch = ind & repmat(trials2use(:,ch),1,4);
    ntr(ch,:)=sum(indch,1);
    for j = 1:size(indch,2)
        erp(ch,:,j) = mean(squeeze(bcorr(ch,:,indch(:,j))),2);
        
    end
end
end
