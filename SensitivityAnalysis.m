function SensitivityAnalysis(EssenFile, DrugResponseFile, Output)
%Performs an associative analysis between interaction essentialties and drug response 
%profiles to discover significant relationships between interaction essentiality and drug
%sensitivity.
%inputs:
%ScaledEssenFile - filename and path of the file containing scaled interaction essentialties
%					generated by 'ScaleEssentialities.m'.
%DrugResponseFile - filename and path of the file containing drug response profiles generated
%					by 'CCLEDrugResponse.m'.
%Output - desired filename and path for output table describing the pearson correlation coefficients
%			and p-values for correlations between sensitivity profiles and interaction essentialities.
%			in this table each row represents an interaction/drug pair, and the R^2 value, 
%			p-value and number of cell lines used in the comparison are noted in the columns.

%Licensed to the Apache Software Foundation (ASF) under one
%or more contributor license agreements.  See the NOTICE file
%distributed with this work for additional information
%regarding copyright ownership.  The ASF licenses this file
%to you under the Apache License, Version 2.0 (the
%"License"); you may not use this file except in compliance
%with the License.  You may obtain a copy of the License at
%
%  http://www.apache.org/licenses/LICENSE-2.0
%
%Unless required by applicable law or agreed to in writing,
%software distributed under the License is distributed on an
%"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%KIND, either express or implied.  See the License for the
%specific language governing permissions and limitations
%under the License.

load(EssenFile);
lines = Essentialities.Lines;
ess_values = Essentialities.Values;

load(DrugResponseFile)
ccle_lines = CCLE.Lines;
ccle_lines = upper(ccle_lines);
ccle_AUC = CCLE.AUC;

if (size(ccle_lines,2) == 1)
    lines = lines';
end

unmapped_cellLines = ~ismember(lines,ccle_lines);
lines(unmapped_cellLines) = [];
ess_values(:,unmapped_cellLines) = [];

unmapped_cellLines = ~ismember(ccle_lines,lines);
ccle_lines(unmapped_cellLines) = [];
ccle_AUC(:,unmapped_cellLines) = [];

[un idx_last idx] = unique(ccle_lines(:,1));
unique_idx = accumarray(idx(:),(1:length(idx))',[],@(x) {sort(x)});

mapped = StringMatch(lines,ccle_lines);
ccle_AUC = CCLE.AUC(:,cell2mat(mapped)); 
ccle_lines = ccle_lines(cell2mat(mapped));

new_ess_values = zeros(size(ess_values,1),length(ccle_lines));
new_ess_values(:,:) = ess_values(:,idx);

[G,N] = size(Essentialities.Values);
correl = zeros(G,length(CCLE.Compounds));
pval = zeros(G,length(CCLE.Compounds));
n_cellLines = zeros(G,length(CCLE.Compounds));

for i = 1:G
    for j=1: length(CCLE.Compounds)
        e = new_ess_values(i,:)';
        auc = ccle_AUC(j,:)';
        nans = find(isnan(e));
        e(nans) = [];
        auc(nans) = [];
        
        nans = find(isnan(auc));
        e(nans) = [];
        auc(nans) = [];
               
        [RHO,PVAL] = corr(e,auc);
        correl(i,j) = RHO;
        pval(i,j) = PVAL;
        n_cellLines(i,j) = length(e);
    end
end

Target = Essentialities.Target;
Source = Essentialities.Source;

siz = size(ccle_AUC,1) * length(Target);
r_n_cellLines = reshape(n_cellLines,[1,siz]);
r_correl = reshape(correl,[1,siz]);
r_pval = reshape(pval,[1,siz]);

r_Target = Target';
r_Source = Source';

for i=1:(length(CCLE.Compounds)-1)
   r_Target = [r_Target,Target'];
   r_Source = [r_Source,Source'];
end

ppi = strcat(r_Source,'-',r_Target);

r_drug = {};

for i = 1:length(CCLE.Compounds)
    d = cell(length(Target),1);
    [d{:}] = deal(CCLE.Compounds{i});
    r_drug = [r_drug,d'];
end

T = table(ppi' ,r_drug',r_correl',r_pval',r_n_cellLines');
writetable(T,Output,'Delimiter','\t')

end
