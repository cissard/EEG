function [eegf stims trigs] = preprocessing(bb,filtType,order,DC,hp,lp);
% load in eeg data
eegfile = sprintf('FM%d.eeg',bb);
trfile = sprintf('FM%d.vmrk',bb);
fid = fopen(eegfile,'r');
d = fread(fid,'float32');
fclose(fid);
eeg = reshape(d,11,[]); % reshape multiplexed channels
fs = 1/2000e-6; % fs from header file

%correct for DC offset
if strcmp(DC,'y')
    for i = size(eeg,1)
        eeg = detrend(eeg,'constant')
    end
end

% filter
if strcmp(filtType,'bp')
    % band pass filter
    bpfreqs = [hp lp]; 
    [b,a] = butter(order,bpfreqs/(fs/2),'bandpass');
elseif strcmp(filtType,'hp');
    % high pass filter
    order = 2*order;
    [b,a] = butter(order,hp/(fs/2),'high');
elseif strcmp(filtType,'lp');
    % low pass filter
    order = 2*order;
    [b,a] = butter(order,lp/(fs/2),'low');
end

for i = 1:size(eeg,1)
    eegf(i,:) = filtfilt(b,a,eeg(i,:));
end
clear a b

% load in marks
delimiterIn = ',';
headerlinesIn = 12;
a = importdata(trfile,delimiterIn,headerlinesIn);
ts = a.data(a.data(:,2) == 1,1);
for l = headerlinesIn+1:length(a.textdata)
    ts(l-headerlinesIn,2) = str2num(a.textdata{l,2}(2:end));
end

% Scramble silent periods
if bb<=6
    scramble='yes';
else
    scramble='no';
end

if strcmp(scramble,'yes')
    for i=1:length(ts)-1
        if ts(i,2) == 12 && ts(i+1,2) == 12
            ts(i+1,1) = ts(i,1)+(randi([4 7]*fs));
        elseif ts(i,2) == 12 && ts(i+1,2) ~= 12 
            while ts(i,1)>= ts(i+1,1) - 4*fs %if the epoch around the last silence trigger of the beginning overlaps with the 1st sound
                ts(i,1) = ts(i-1,1)+(randi([4 5]*fs));
            end
        end
    end
end

tdiff = diff(ts(:,1) / fs);
trigs = ts(:,1) + (0.04 * fs); %correct for sound delay (40 ms)
stims = ts(:,2);

% plot them together
figure(bb)
clf;
hold on
linemax = repmat(max(eegf(:)),length(trigs),1);
linemin = repmat(min(eegf(:)),length(trigs),1);
line([trigs trigs]',[linemax linemin]','Color',[0 0 0]);
plot(eegf')
hold off

end