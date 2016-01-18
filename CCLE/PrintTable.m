function PrintTable(superpathwayFile,ScaledEssenFile,Output)

load(superpathwayFile);
p_Novel  = Novel;

load(ScaledEssenFile);
Source = Essentialities.Source;
Target = Essentialities.Target ;
essen_table = Essentialities.Labels;

for i = 1:size(labels,1)
    
    for j = 1:size(labels,2)
        if(~isnan(Essentialities.Values(i,j)))
            essen_table{i}{j} = {num2str(Essentialities.Values(i,j))};
        end
            
    end
end

Pathways = cell(length(Source),1);

for i =1:length(Source)
    Pathways{i} = PathwayNames(PathwayMapping{i});
end

p = cellfun(@(x)ReLimit(x, ','), Pathways, 'UniformOutput', false);
% table = PrintPPIEssentiality(all_Essentialities, Source, Target,...
%                                    p_Novel, p, Lines,Histology );
table = PrintPPIEssentiality(essen_table, Source, Target,...
                                   p_Novel, p, Lines,Histology );
result = cell2text(table, Output);



