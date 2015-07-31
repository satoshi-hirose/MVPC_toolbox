%% General information
function save_figures_general_info(MY_VAR)

load(fullfile(MY_VAR.figure_dir,'results_fig.mat'), 'Spatial_ROI','Temporal_ROI', 'Method_info','Param_search')

figure;
tmp = get(gcf,'Position');
set(gcf,'Position',[tmp(1:2) 800 800],'PaperType','A4')
set(gca,'Position',[0 0 1 1],'Visible','off')

start_line = write_text('Results Files:',1);
start_line = write_text(['    ' fullfile(MY_VAR.analyze_dir,MY_VAR.decoding_dir,MY_VAR.result_dir)],start_line+1);

% subject names
subs = [];
for sub = 1:length(MY_VAR.subnames)
subs = [subs MY_VAR.subnames{sub} '; '];
end

start_line = write_text('Subject Names',start_line+1);
start_line = write_text(['    ' subs],start_line+1);

% Decoding Methods
methods = [];
for methodn = 1:length(MY_VAR.method)
methods = [methods MY_VAR.method{methodn} '; '];
end

start_line = write_text('Decoding Algorithms',start_line+1);
start_line = write_text(['    ' methods],start_line+1);

% Temporal ROIs
te_ROIs = [];
for te = 1:size(Temporal_ROI,1)
    te_ROIs = [te_ROIs num2str(Temporal_ROI{te}.timing(:)') '; '];
end

start_line = write_text('Temporal ROIs',start_line+1);
start_line = write_text(['    ' te_ROIs],start_line+1);

% Spatial ROIs
start_line = write_text('Spatial ROIs',start_line+1);

sp_ROIs_cap = 'Method         Activation Map  Threshold  Threshold(Cluster-Size) Threshold(T-Value) Cluster Index';

start_line = write_text(sp_ROIs_cap,start_line+1);

for sp = 1:size(Spatial_ROI,1)
    tmp = Spatial_ROI{sp}.ROI_param.method;
    method_str = '               ';
    method_str(1:length(tmp)) = tmp;

    actmap_str = '                ';
    if isfield(Spatial_ROI{sp}.ROI_param,'act_map')
        tmp = Spatial_ROI{sp}.ROI_param.act_map;
        actmap_str(1:length(tmp)) = tmp;
    end
    
    threshold_str = '            ';
    if isfield(Spatial_ROI{sp}.ROI_param,'threshold')
        tmp = num2str(Spatial_ROI{sp}.ROI_param.threshold);
        threshold_str(1:length(tmp)) = tmp;
    end
    
    cthreshold_str = '                        ';
    if isfield(Spatial_ROI{sp}.ROI_param,'extend_threshold')
        tmp = int2str(Spatial_ROI{sp}.ROI_param.extend_threshold);
        cthreshold_str(1:length(tmp)) = tmp;
    end
    
    tthreshold_str = '                   ';
    if isfield(Spatial_ROI{sp}.ROI_param,'threshold_height')
        tmp = num2str(Spatial_ROI{sp}.ROI_param.threshold_height);
        tthreshold_str(1:length(tmp)) = tmp;
    end
    
    ind_clu_str = '                  ';
    if isfield(Spatial_ROI{sp}.ROI_param,'cluster_num')
        tmp = int2str(Spatial_ROI{sp}.ROI_param.cluster_num);
        ind_clu_str(1:length(tmp)) = tmp;
    end
    
    if isfield(Spatial_ROI{sp}.ROI_param,'areas') && ~isempty(Spatial_ROI{sp}.ROI_param.areas)
        areas_str = ['               (AREAS: ' area_list(Spatial_ROI{sp}.ROI_param.areas,MY_VAR.anato_map) ')'];
    else
        areas_str = '';
    end
start_line = write_text([method_str,actmap_str,threshold_str,cthreshold_str,tthreshold_str,ind_clu_str,areas_str],start_line+1);
end

print('-dpsc','-append',fullfile(MY_VAR.figure_dir,MY_VAR.figure_fname));
close all

function [end_line str] = write_text(str,start_line)

temp = start_line;
str_curr = deblank(str);
    
for j = 1:ceil(length(str_curr)/100)
    if j == ceil(length(str_curr)/100)
        str_write = str_curr((j-1)*100+1:end);
    else
        str_write = str_curr((j-1)*100+1:j*100);
    end
    text(0.01,0.99-0.03*temp,str_write,'Interpret','none','FontSize',8,'FontName','Courier')
    temp = temp + 1;
end
end_line = temp - 1;