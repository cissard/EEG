% clear all
np=[14 15 16 17 18 19 20 21 22 24];%1 2 3 4 5 6 7 8 9 10 11 12 13 
nchannels=11;
ntrials=zeros(nchannels,4,length(np));
trigsil = 4;
trig1 = 10;
trig2 = 20;
trig3 = 30;
str = {'silence','normalFM','FM/4','FM*4','trigger'};

% electrode positions
electrodes = {'F3','F4','C3','Fz','TP10','F7','F8','T7','T8','TP9','C4'};

for bb=np
    [eegf stims trigs] = preprocessing(bb,'bp',1,'n',0.5,30); 
    [epochs ind t] = defineEpochs(eegf,stims,trigs,500,0.3,2,trigsil,trig1,trig2,trig3);
    %plotTrials
    PlotTrials
    waitforbuttonpress
    
    [erp ntr] = computeERP(ind,epochs,t,150,3,0.2); %channel x time x condition
    ntrials(:,:,bb)=ntr;
    ERP(:,:,:,bb)=erp;
    clear ntr erp
end

% plot colors and labels
colorSEM = [.5 .5 .5; ...
            .2 .2 1; ...
            .2 1 .2; ...
            1 .2 .2];
colorMean = [0 0 0;
             0 0 1;
             0 1 0;
             1 0 0];


% plotting ERPs
f = figure(length(np)+1);
clf;
for ch = 1:nchannels
    clear h
    subplot(2,6,ch)
    plot([min(t) max(t)],[0 0],'k','LineWidth',2);
    set(gca,'LineWidth',2)
    for j = 1:size(ind,2)
       
        % plot ERP
        hold on
        gravg = squeeze(mean(ERP,4));
        sem = std(ERP,0,4) / sqrt(length(np) - 1);
        X = [gravg(ch,:,j)+sem(ch,:,j) fliplr(gravg(ch,:,j)-sem(ch,:,j))];
        Y = [t fliplr(t)];
        p = patch(Y',X',colorSEM(j,:));
        p.FaceAlpha = .3;
        p.EdgeColor = 'none';
        h(j) = plot(t,gravg(ch,:,j),'Color',colorMean(j,:),'LineWidth',2);
        hold off
    end
    
    % legend and formatting
    if ch == 1
        ylabel('Voltage (uV)')
        xlabel('Time(s)');
    end
    title(sprintf('Electrode %02d-%s',ch,electrodes{ch}));
    set(gca,'FontSize',16);
    set(gca,'TickDir','out')
    xlim([min(t) max(t)]);
    ylim([-5 5]);
    box off
    grid on
    % plot trigger
    hold on
    h(end+1) = plot([0 0],ylim,'--k','LineWidth',1.5);
    hold off
    if ch == nchannels
        legend(h,str(1:end-1),'Position',[0.8, 0.1, 0.15, 0.2])
    end
end
