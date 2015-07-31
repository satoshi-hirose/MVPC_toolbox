% Temporal ROI assinment
% temporal normalization (divide with mean, dividde with sd) 
% and averaging are also performed.
% 


function assigned_data = assign_tempo_ROI(rawdata,tempo_ROI,normalization_method)
assigned_data = rawdata;

                for sess = 1:length(tempo_ROI)
                    % data massage & assign temporal mask
                    if normalization_method(1) % temporal mean to 100
                        assigned_data{sess} = assigned_data{sess}./repmat(mean(assigned_data{sess},1),[size(assigned_data{sess},1),1])*100;
                    end
                    
                    if normalization_method(2) % temporal normalize (Z-score)
                        assigned_data{sess} = (assigned_data{sess}-repmat(mean(assigned_data{sess},1),[size(assigned_data{sess},1),1]))./repmat(std(assigned_data{sess},1,1),[size(assigned_data{sess},1),1]);
                    end
                    
                    if size(tempo_ROI{sess},2)>1 %% averaging temporal ROI
                        
                        assign_temp = NaN(size(tempo_ROI{sess},1),size(assigned_data{sess},2),size(tempo_ROI{sess},2));
                        for ave = 1:size(tempo_ROI{sess},2)
                            assign_temp(:,:,ave) = assigned_data{sess}(tempo_ROI{sess}(:,ave),:); % assign temporal_ROI
                        end
                        assigned_data{sess} = mean(assign_temp,3);
                    else
                        assigned_data{sess} = assigned_data{sess}(tempo_ROI{sess},:); % assign temporal_ROI
                    end
                    
                    
                    if normalization_method(3) % temporal normalization assign to samples in temporal_ROI
                        assigned_data{sess} = (assigned_data{sess}-repmat(mean(assigned_data{sess},1),[size(assigned_data{sess},1),1]))./repmat(std(assigned_data{sess},1,1),[size(assigned_data{sess},1),1]);
                    end
                    
                    if normalization_method(4) % spatial normalize assign to samples in temporal_ROI
                        assigned_data{sess} = (assigned_data{sess}-repmat(mean(assigned_data{sess},2),[1,size(assigned_data{sess},2)]))./repmat(std(assigned_data{sess},1,2),[1,size(assigned_data{sess},2)]);
                    end
                    
                    
                    
                end
                
