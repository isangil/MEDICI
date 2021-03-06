function PathwaysTable = CCLEBuildPathwaysTable(SuperpathwayFile,CNFile,CaptureFile, Output)
%Builds context specific pathway for each cell line according to the
%mutaions and copy number values. 
%inputs:
%superpathwayFile - filename and path to superpathway file containing
%                   Sources and Targets of interactions.
%CNFile - filename and path to CN file which is the output file of the 
%         'CCLEBuildCNV.m' function. 
%CaptureFile - filename and path to the CaptureFile which is the output of
%              the 'CCLEHybridCapture.m'             
%Output - filename and path to store output variables.
%outputs
%A structure 'PathwaysTable' with the following fields:
%   PathwaysTable.Lines - N-length cell array of strings describing cell line identifiers.
%   PathwaysTable.Labels - an MxN cell array of strings indicating the type
%                       of alterations(mutations-copynumber) for each gene
%                       in each cell line.
%   PathwaysTable.Values - an MxN matrix indicating whether a gene exists
%   in a cell line(0) or not(NaN)

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
             
load(SuperpathwayFile)

load(CNFile)
cn_lines = CN.Lines';
cn = CN.CNV;
cn_labels = CN.Labels;

load(CaptureFile)
mut_lines = Capture.Lines;
mutations = Capture.Mutations;
mutation_labels = Capture.Labels;
histology = Capture.Histology;

gene_set = union(CN.Symbols,Capture.Symbols);
mut_genes = Capture.Symbols; 
cn_genes = CN.Symbols; 

unmapped_cellLines = ~ismember(cn_lines,mut_lines);
cn_lines(unmapped_cellLines) = [];
cn(:,unmapped_cellLines) = [];
cn_labels(:,unmapped_cellLines) = [];

unmapped_cellLines = ~ismember(mut_lines,cn_lines);
mut_lines(unmapped_cellLines) = [];
histology(unmapped_cellLines) = [];
mutations(:,unmapped_cellLines) = [];
mutation_labels(:,unmapped_cellLines) = []; 
mutations(isnan(mutations)) = 1;

Mapping = StringMatch(cn_lines,mut_lines);
mapping = cell2mat(Mapping)';
c_cn = zeros(size(cn));
c_cn_lines = cn_lines;
c_cn(:,mapping) = cn;
cn_labels(:,mapping) = cn_labels;
c_cn_lines(mapping) = cn_lines;

lines = c_cn_lines;

table1 = zeros(length(gene_set),length(lines));
table2 = zeros(length(gene_set),length(lines));


%Find genes with copy number less than -1 and mark them to be removed
for i = 1: length(lines)
    ind = find(c_cn(:,i)<-1);
    c_cn(:,i) = 0;
    c_cn(ind,i) = 1;
end

Mapping_mut = StringMatch(mut_genes,gene_set);
mapping_mut = cell2mat(Mapping_mut)';
Mapping_cn = StringMatch(cn_genes,gene_set);
mapping_cn = cell2mat(Mapping_cn)';

table1(mapping_mut,:) = mutations;
table2(mapping_cn,:) = c_cn;
table = table1 | table2;

pathway_source = zeros(length(Source),length(lines));
pathway_target = zeros(length(Source),length(lines));
pathway = zeros(length(Source),length(lines));

labels = cell(length(Source),length(lines));

for k = 1:length(lines)
    
    for j = 1:length(Source)
        [~, ind_1] = ismember(Source{j}, mut_genes);
        s_m = '';
        if (ind_1 ~= 0)
            s_m = mutation_labels{k}{ind_1};
        end
        [~, ind_2] = ismember(Source{j}, cn_genes);
        s_cn = '';
        if (ind_2 ~= 0)
            s_cn = cn_labels{k}{ind_2};
        end
        s = strcat(s_m,s_cn);
        s1 = '';
        if(~isempty(s))
            s1 = strcat('Source:',s);
        end
        [~, ind_1] = ismember(Target{j}, mut_genes);
        t_m = '';
        if (ind_1~=0)
            t_m = mutation_labels{k}{ind_1};
        end
        [~, ind_2] = ismember(Target{j}, cn_genes);
        t_cn = '';
        if (ind_2~=0)
            t_cn = cn_labels{k}{ind_2};
        end
        s = strcat(t_m,t_cn);
        s2 = '';
        if(~isempty(s))
            s2 = strcat('Target:',s);
        end
        s = strcat(s1,s2);
        labels{j}{k} = {s};
    end
end

for i = 1:length(lines)
    Mapping = StringMatch(Source,gene_set);
    mapping = cell2mat(Mapping)';
    member = find(ismember(Source,gene_set));
    pathway_source(member,i) = table(mapping,i);
    
    
    Mapping = StringMatch(Target,gene_set);
    mapping = cell2mat(Mapping)';
    member = find(ismember(Target,gene_set));
    pathway_target(member,i) = table(mapping,i);
    
    value = pathway_source(:,i) | pathway_target(:,i);
    value = value + 0; %convert logical to numeric
    value(value==1) = nan;
    pathway(:,i) = value;
    
end

PathwaysTable.Lines = lines;
PathwaysTable.Labels = labels;
PathwaysTable.Values = pathway;
PathwaysTable.Histology = histology;

%save data
save(Output, 'PathwaysTable');

end
