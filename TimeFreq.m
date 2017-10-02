clear all
np=[14 15 17 18 19 20];%1 2 3 4 5 6 7 8 9 10 11 12 13 16
nchannels=11;
electrodes = {'F3','F4','C3','Fz','TP10','F7','F8','T7','T8','TP9','C4'};

fs = 500;
ntrials=zeros(nchannels,4,length(np));
trigsil = 4;
trig1 = 10;
trig2 = 20;
trig3 = 30;

freq = [1:30];
ncycles = round(linspace(3,10,30));
% ncycles(1) = 3;
% ncycles(2) = 4;
% ncycles(3:5) = 5;
% ncycles(6:30) = 6;
% ncycles(6:20) = 7;
% ncycles(6:30) = 8;
% ncycles(6:30) = 9;
% ncycles(6:30) = 10;

str = {'silence','normalFM','FM/4','FM*4','trigger'};

norm_power = zeros(nchannels,3001,4,length(freq),max(np));
for bb=np
    [eegf stims trigs] = preprocessing(bb,'hp',1,'n',0.5);
    [epochs ind t] = defineEpochs(eegf,stims,trigs,fs,2,4,trigsil,trig1,trig2,trig3); %long epochs because of edge artefacts
    
    % remove bad trials
    % make a matrix of bad electrodes per trial
    badTrials = squeeze(any(epochs>100,2) | any(epochs<-100,2))';
    
    % set number of bad electrodes to completely discount a trial
    % if above this number, remove the trial completely; if below this
    % number, just remove bad electrodes
    for i = 1:size(badTrials,1)
        % if more bad electrodes than cutoff
        if sum(badTrials(i,:)) > 3
            % completely remove all electrodes on this trial
            trials2use(i,:) = zeros(1,11);
        else
            % otherwise, remove only bad electrodes
            trials2use(i,:) = ~ badTrials(i,:);
        end
    end
    
    %baseline parameters
    s = -0.5; %start of the baseline period
    e = -0.2; %end of the baseline period
    
    sound_onset = find(t==0);
    b_start = sound_onset + round(s*fs);
    b_end = sound_onset + round(e*fs);
    time_of_interest = t(b_start:find(t ==2));
    
    tic
    for fr = freq
        time  = -2:1/fs:2;
        sine_wave = exp( 1i*2*pi*fr.*time );
        
        % create Gaussian window
        s = ncycles(fr) / (2*pi*fr);
        gaus_win  = exp( (-time.^2) ./ (2*s^2) );
        
        
        % now create Morlet wavelet
        cmw = sine_wave .* gaus_win;
        
        %concatenate trials to decrease computation time
        for ch = 1:nchannels
            
            
            datach = squeeze(epochs(ch,:,:));
            data = reshape(datach,1,[]);
            
            nData = length(data);
            nKern = length(cmw);
            nConv = nData + nKern - 1;
            
            %multiplication in the frequency domain
            cmwX = fft(cmw,nConv);
            dataX = fft(data,nConv);
            conv_res = cmwX .* dataX;
            
            
            % cut 1/2 of the length of the wavelet from the beginning and from the end
            half_wav = floor( length(cmw)/2 )+1;
            
            % take inverse Fourier transform
            conv_res_timedomain = ifft(conv_res);
            
            conv_res_timedomain = conv_res_timedomain(half_wav-1:end-half_wav);
            power_ch = abs(conv_res_timedomain).^2;
            
            %separate trials
            power_fr(ch,:,:) = reshape(power_ch,[],size(datach,2));
            
            %good trials for that channel
            indch = ind & repmat(trials2use(:,ch),1,4);
            ntr(ch,:)=sum(indch,1);
            
            %dB normalization
            silence = squeeze(mean (power_fr(ch,:,indch(:,1)),3));
            for c = 2:size(indch,2)
                mean_power_condch = squeeze(mean (power_fr(ch,:,indch(:,c)),3));
                %baseline = mean(mean_power_condch(:,b_start:b_end),2);
                norm_power_condch = 10 * log10(mean_power_condch ./ silence);
                norm_power(ch,:,c,fr,bb) = norm_power_condch;
            end
            
        end
        SNR(:,:,fr) = mean(power_fr,3)./std(power_fr,1,3);
    end
    toc
    
    ntrials(:,:,bb)=ntr;
    
    f = figure(bb)
    f.Name = sprintf('SNR baby %02d',bb)
    for ch = 1:nchannels
        subplot(2,6,ch)
        imagesc(time_of_interest,freq,squeeze(SNR(ch,(b_start:find(t ==2)),:))');
        set(gca,'ydir','normal');
        hold on
        plot([0 0],[min(freq) max(freq)],'--k','LineWidth',1);
        hold off
            title(sprintf('Electrode %02d-%s',ch,electrodes{ch}));
        if ch == 1
            ylabel('Frequency (Hz)')
            xlabel('Time(s)');
        end
    end
    h = colorbar('Position',[0.9, 0.1, 0.02, 0.35])
    h.Label.String = 'SNR (arbitrary units)'
    saveas(f,sprintf('SNR baby %02d',bb))
end
gravg_power = mean(norm_power,5);

for c = 2:size(ind,2)
   %plot
    f = figure(c);clf
    f.Name = str{1,c}
    for ch = 1:nchannels
        subplot(2,6,ch)
        imagesc(time_of_interest,freq,squeeze(gravg_power(ch,(b_start:find(t ==2)),c,:))');
        set(gca,'ydir','normal');
        hold on
        plot([0 0],[min(freq) max(freq)],'--k','LineWidth',1);
        hold off
            title(sprintf('Electrode %02d-%s',ch,electrodes{ch}));
        if ch == 1
            ylabel('Frequency (Hz)')
            xlabel('Time(s)');
        end
    end
    h = colorbar('Position',[0.9, 0.1, 0.02, 0.35])
    h.Label.String = 'Power Change (dB)'
end