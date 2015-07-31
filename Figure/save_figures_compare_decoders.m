% 2010/June/3 SH
% 2010/June/10 IN modified
% 2010/June/11 SH
function save_figures_compare_decoders(MY_VAR)
load(fullfile(MY_VAR.figure_dir,'results_fig.mat'))

for sp = 1:size(Spatial_ROI,1)
    for te = 1:size(Temporal_ROI,1)
        tmp = get(gcf,'Position');
        set(gcf,'Position',[tmp(1:2) 800 800],'PaperType','A4','MenuBar', 'none','PaperUnits', 'normalized', 'PaperPosition',[0.1 0.1 .8 .8])

        
        % set printing parameters
        
        test_correct_mean = NaN(size(Percent_correct{sp,te}));
        method_names = cell(1,size(Method_info,1));
        for methodn = 1:size(Method_info,1)
            method_names{methodn} = Method_info{methodn,1}.name;
            for sub = 1:size(Percent_correct{sp,te},2)
                test_correct_mean(methodn,sub) = Percent_correct{sp,te}{methodn,sub};
            end
        end
        
       %% percent correct bar graph
       hold off     
       bar(mean(test_correct_mean,2),'k'); hold on
            plot(test_correct_mean,'ko--','LineWidth',1,'MarkerFaceColor','w')
            
            plot([0 size(test_correct_mean,1)+1],[50 50],'k--');plot([0 size(test_correct_mean,1)+1],[75 75],'k--');plot([0 size(test_correct_mean,1)+1],[25 25],'k--');hold off;
            axis([0.5 size(test_correct_mean,1)+0.5 0 100]); % set y -axis 0 to 100
            
            set(gca,'xTick',1:size(test_correct_mean,1),'xTickLabel',method_names)
   
         %% title setting
            title_str = strvcat('PERFORMANCE COMPARISON ACROSS DECODING ALGORITHMS', ['Spatial ROI=' Spatial_ROI{sp}.ROI_param.method,'   Temporal ROI=' num2str(Temporal_ROI{te}.timing(:)')]);

            spROI_str = '***Spatial ROI setting***: ';

    if isfield(Spatial_ROI{sp}.ROI_param,'act_map') && ~isempty(Spatial_ROI{sp}.ROI_param.act_map)
        spROI_str = [spROI_str 'Activation Map=' Spatial_ROI{sp}.ROI_param.act_map '; '];
    end
    
    if isfield(Spatial_ROI{sp}.ROI_param,'threshold') && ~isempty(Spatial_ROI{sp}.ROI_param.threshold)
        spROI_str = [spROI_str 'T(or num of voxels) threshold=' num2str(Spatial_ROI{sp}.ROI_param.threshold) '; '];
    end
    
    if isfield(Spatial_ROI{sp}.ROI_param,'extend_threshold') && ~isempty(Spatial_ROI{sp}.ROI_param.extend_threshold)
        spROI_str = [spROI_str 'Threshold(Cluster-Size)=' int2str(Spatial_ROI{sp}.ROI_param.extend_threshold) '; '];
    end
    
    
    if isfield(Spatial_ROI{sp}.ROI_param,'threshold_height') && ~isempty(Spatial_ROI{sp}.ROI_param.threshold_height)
        spROI_str = [spROI_str 'Threshold(T-Value)=' num2str(Spatial_ROI{sp}.ROI_param.threshold_height) '; '];
    end
    
    if isfield(Spatial_ROI{sp}.ROI_param,'cluster_num') && ~isempty(Spatial_ROI{sp}.ROI_param.cluster_num)
        spROI_str = [spROI_str 'Cluster Index=' int2str(Spatial_ROI{sp}.ROI_param.cluster_num) '; '];
    end
    
    if isfield(Spatial_ROI{sp}.ROI_param,'areas') && ~isempty(Spatial_ROI{sp}.ROI_param.areas)
        spROI_str = [spROI_str 'Areas= ' area_list(Spatial_ROI{sp}.ROI_param.areas,MY_VAR.anato_map)];
    end

    spROI_str = add_return(spROI_str,100);
            
    text(0,1.1,title_str,'Units','normalized','VerticalAlignment','Top','FontName','Helvetica','FontSize',12,'Interpret','none')
    
    text(0,-0.05,spROI_str,'Units','normalized','Interpret','none','FontSize',8,'FontName','Courier')
    
    
    
    print('-dpsc','-append',fullfile(MY_VAR.figure_dir,MY_VAR.figure_fname));

    end
end
close all