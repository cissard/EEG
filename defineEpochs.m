function [epochs ind t] = defineEpochs(eegf,stims,trigs,fs,pre,post,trigsil,trig1,trig2,trig3);
t = -pre:1/fs:post;
nchannels = size(eegf,1);

% Build some indices for conditions
% stim types:
% 100 = normal
% 200 = FM/4
% 300 = FM*4
% *[01-12] = sentences
% 12 = silence
silence = stims == trigsil;
normFM = stims >= trig1 & stims < trig2;
slowFM = stims >= trig2 & stims < trig3;
fastFM = stims >= trig3;
ind = [silence normFM slowFM fastFM];

%define epochs
for i = 1:length(trigs)
    for j = 1:nchannels
        s = trigs(i) - round(pre*fs);
        e = trigs(i) + round(post*fs);
        epochs(j,:,i) = eegf(j,s:e);
    end
end

end