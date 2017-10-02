
%     if bb == 24
%     clf;
%     for trial = 1:size(epochs,3)
%         for e = 1:size(epochs,1)
%             subplot(2,6,e)
%             plot(t, epochs(e,:,trial))
%             xlim([-0.2 2])
%         end
%         waitforbuttonpress
%     end
%     end

    %plot ERP images
    
    
for cond = 1:size(ind,2)    
    f = figure(cond)
    f.Name = sprintf('ERP image baby %02d-%s',bb,str{1,cond})
    for ch=1:nchannels
        subplot(2,6,ch)
        imagesc(t,[1:sum(ind,1)],squeeze(epochs(ch,:,ind(:,cond)))');
        hold on
        plot([0 0],ylim,'--k','LineWidth',1);
        hold off
        title(sprintf('Electrode %02d-%s',ch,electrodes{ch}));
        set(gca,'FontSize',16);
        set(gca,'ydir','normal');
        if ch == 1
            ylabel('Trial')
            xlabel('Time(s)');
        end
    end
    
    %legend
    h = colorbar('Position',[0.9, 0.1, 0.02, 0.35])
    h.Label.String = 'Voltage(uV)'
end