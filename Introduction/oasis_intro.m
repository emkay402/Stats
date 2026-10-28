% %% OASIS-1 cross-sectional data: first steps in MATLAB
% Goal: get comfortable with the dataset *before* running any statistics.
% Data: |oasis_cross-sectional.csv| (Marcus et al., 2007). Keep it in the same folder as this script.
%%
%%\ 1. LOAD THE DATASET
% |readtable| reads a CSV file into a *table*: columns can have different types, and each column has a name.
% |"TextType","string"| makes sure that columns with text entries are
% handled correctly, and are not treated as numbers.
% Ending a line with a semi-colon (;) does not produce an output
T = readtable("oasis_cross-sectional.csv", "TextType", "string"); %[output:877facdb]
%%
%%\ INSPECT THE SHAPE
size(T) %[output:8df3f8ba]
%%
%%\
[nRows, nCols] = size(T) %[output:6e38e16b] %[output:296e74d6]
% The fact sheet says 416 subjects, but we have 436 rows. Why is that?
% Answer: There were 20 repeat sessions.
%%
%%\ 2. Look at the columns
T.Properties.VariableNames %[output:8b97a458]
%%
%%\
% Note: the column |M/F| is called |M_F| in MATLAB, because "/" is not allowed in a variable name.
%
% * |ID|: session identifier (|MR1| = first scan, |MR2| = repeat scan)
% * |M_F|: sex (M / F)
% * |Hand|: handedness (all R)
% * |Age|: age in years
% * |Educ|: education level, 1 (< high school) to 5 (beyond college)
% * |SES|: socioeconomic status, 1 to 5 (1 = highest, 5 = lowest; verify in Marcus et al., 2007)
% * |MMSE|: cognitive screening score, 0 to 30 (higher = better)
% * |CDR|: Clinical Dementia Rating (0, 0.5, 1, 2)
% * |eTIV|, |nWBV|, |ASF|: brain volume measures
% * |Delay|: days between repeat scans
summary(T) %[output:8585ef3b]
%%
%%\ 3. View the first rows
head(T) %[output:37c7fc68]
%%
% View the first 10 rows
head(T, 10) %[output:0a76778f]
%%
% View the last rows
tail(T) %[output:7b725b6c]
%%
% View the last 5 rows
tail(T, 5) %[output:7e9e68c8]
%%
% Missing values are shown as |NaN| (numeric columns).
% Younger participants have no |Educ|, |SES|, |MMSE| or |CDR|.
%%
% 4. STRUCTURE OF A TABLE AND HOW TO ACCESS ELEMENTS
% A table is a collection of named columns, and each column is an ordinary array.
% An array is an ordered collection of elements.
% Important: MATLAB counts from 1, not from 0.
class(T) %[output:54f2ef4e]
class(T.Age) %[output:1db51d36]
%%
%%\ 4a. Column name first, then index
T.Age(1) %[output:53cadf05]
%%\
T.Age(1:5) %[output:7f9388bd]
%%
%%\ 4b. Like a matrix: row, column by position
% Curly braces |{ }| return the content. Round brackets |( )| return a smaller table.
T{1, 4} %[output:5fcdca73]
%%\ Tangent: Smaller table covering rows 1-5 and columns 3-5
T(1:5, 3:5) %[output:1234a688]
%%
% All of these return the same value:
[T.Age(1), T{1, 4}, T{1, "Age"}] %[output:18037ba3]
%%
%%\ Say that I am interested in all participants who are 90 years old or older
% I can achieve this by applying a 'filter' on a condition, I am interested
% in the rows of T, where the Age column has values 90 or above 
% (greater than or equal to, >=)
% the colon (:) following the comma means that I would like to get all
% columns
oldest = T(T.Age >= 90, :);
%%
% After filtering, rows are renumbered, so row 1 is always the first row of the current table.
head(oldest, 3) %[output:6d3121a8]
%%
oldest.Age(1) %[output:26ddb183]
%%
%%\ 5. Inspecting a single column
% Let's focus on |SES|
%%
%%\ 5a. How many entries are there?
height(T.SES) %[output:62c7ec8c]
%%
% That's a little odd, we did see some NaN (missing) values, so why do we
% still have 436 entries?
% NaN are placeholder entries for missing values, these are special and
% have some functions built around them to make our lives easier
%%
% If NaN represent missing values, then we can make use of a function like
isnan(T.SES) %[output:6143b4bb]
% This function places a 1 if the value is NaN, if we would like to count
% the total number of missing values, we can do:
nMissing = sum(isnan(T.SES)) %[output:47746a9a]
%%
% Conversely, we can count the number of non-missing entries by flipping
% our approach on its head
% By negating the output of isnan(T.SES), we mark non-missing value with 1
% and missing values with 0
% ~ is the negation symbol
~isnan(T.SES) %[output:4e987cd3]
%%
nNotMissing = sum(~isnan(T.SES)) %[output:020567ca]
%%
% Alternatively
nMissing = sum(isnan(T.SES)) %[output:40b3cf7a]
nNotMissing = height(T.SES) - nMissing %[output:45325444]
%%
% For a given array, we can also check for unique values using unique()
% the rmmissing() function discards missing values
rmmissing(unique(T.SES)) %[output:487dda35]
%%
% We can count the number of unique values using
numel(rmmissing(unique(T.SES))) %[output:18acbca1]
%%
%%\ Recap
% * |readtable|, |size|, |head|, |summary| give a first overview.
% * Access elements with |T.Age(i)|, |T{i, j}| / |T(i, j)| (position, from 1) and |T{i, "Age"}| (column name).
% * |height|, |isnan|, |unique|, |groupcounts| show how many entries a column has and which values it takes.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":41.7}
%---
%[output:877facdb]
%   data: {"dataType":"warning","outputData":{"text":"Warning: Column headers from the file were modified to make them valid MATLAB identifiers before creating variable names for the table. The original column headers are saved in the VariableDescriptions property.\nSet 'VariableNamingRule' to 'preserve' to use the original column headers as table variable names."}}
%---
%[output:8df3f8ba]
%   data: {"dataType":"matrix","outputData":{"columns":2,"name":"ans","rows":1,"type":"double","value":[["436","12"]]}}
%---
%[output:6e38e16b]
%   data: {"dataType":"textualVariable","outputData":{"name":"nRows","value":"436"}}
%---
%[output:296e74d6]
%   data: {"dataType":"textualVariable","outputData":{"name":"nCols","value":"12"}}
%---
%[output:8b97a458]
%   data: {"dataType":"matrix","outputData":{"columns":12,"header":"1×12 cell array","name":"ans","rows":1,"type":"cell","value":[["'ID'","'M_F'","'Hand'","'Age'","'Educ'","'SES'","'MMSE'","'CDR'","'eTIV'","'nWBV'","'ASF'","'Delay'"]]}}
%---
%[output:8585ef3b]
%   data: {"dataType":"text","outputData":{"text":"\n<strong>T<\/strong>: 436×12 table\n\nVariables:\n\n    <strong>ID<\/strong>: string (ID)\n    <strong>M_F<\/strong>: string (M\/F)\n    <strong>Hand<\/strong>: string (Hand)\n    <strong>Age<\/strong>: double (Age)\n    <strong>Educ<\/strong>: double (Educ)\n    <strong>SES<\/strong>: double (SES)\n    <strong>MMSE<\/strong>: double (MMSE)\n    <strong>CDR<\/strong>: double (CDR)\n    <strong>eTIV<\/strong>: double (eTIV)\n    <strong>nWBV<\/strong>: double (nWBV)\n    <strong>ASF<\/strong>: double (ASF)\n    <strong>Delay<\/strong>: string (Delay)\n\nStatistics for applicable variables:\n\n             <strong>NumMissing<\/strong>       <strong>Min<\/strong>            <strong>Median<\/strong>           <strong>Max<\/strong>             <strong>Mean<\/strong>             <strong>Std<\/strong>     \n\n    <strong>ID   <\/strong>         0                                                                                    \n    <strong>M_F  <\/strong>         0                                                                                    \n    <strong>Hand <\/strong>         0                                                                                    \n    <strong>Age  <\/strong>         0              18                54            96           51.3578         25.2699  \n    <strong>Educ <\/strong>       201               1                 3             5            3.1787          1.3115  \n    <strong>SES  <\/strong>       220               1                 2             5            2.4907          1.1206  \n    <strong>MMSE <\/strong>       201              14                29            30           27.0638          3.6969  \n    <strong>CDR  <\/strong>       201               0                 0             2            0.2851          0.3834  \n    <strong>eTIV <\/strong>         0            1123        1.4755e+03          1992        1.4819e+03        158.7409  \n    <strong>nWBV <\/strong>         0          0.6440            0.8090        0.8930            0.7917          0.0599  \n    <strong>ASF  <\/strong>         0          0.8810            1.1900        1.5630            1.1989          0.1287  \n    <strong>Delay<\/strong>         0                                                                                    \n\n","truncated":false}}
%---
%[output:37c7fc68]
%   data: {"dataType":"text","outputData":{"text":"          <strong>ID<\/strong>           <strong>M_F<\/strong>    <strong>Hand<\/strong>    <strong>Age<\/strong>    <strong>Educ<\/strong>    <strong>SES<\/strong>    <strong>MMSE<\/strong>    <strong>CDR<\/strong>    <strong>eTIV<\/strong>    <strong>nWBV<\/strong>      <strong>ASF<\/strong>     <strong>Delay<\/strong>\n    <strong>_______________<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>_____<\/strong>    <strong>_____<\/strong>    <strong>_____<\/strong>\n\n    \"OAS1_0001_MR1\"    \"F\"    \"R\"     74       2       3     29       0    1344    0.743    1.306    \"N\/A\"\n    \"OAS1_0002_MR1\"    \"F\"    \"R\"     55       4       1     29       0    1147     0.81    1.531    \"N\/A\"\n    \"OAS1_0003_MR1\"    \"F\"    \"R\"     73       4       3     27     0.5    1454    0.708    1.207    \"N\/A\"\n    \"OAS1_0004_MR1\"    \"M\"    \"R\"     28     NaN     NaN    NaN     NaN    1588    0.803    1.105    \"N\/A\"\n    \"OAS1_0005_MR1\"    \"M\"    \"R\"     18     NaN     NaN    NaN     NaN    1737    0.848     1.01    \"N\/A\"\n    \"OAS1_0006_MR1\"    \"F\"    \"R\"     24     NaN     NaN    NaN     NaN    1131    0.862    1.551    \"N\/A\"\n    \"OAS1_0007_MR1\"    \"M\"    \"R\"     21     NaN     NaN    NaN     NaN    1516     0.83    1.157    \"N\/A\"\n    \"OAS1_0009_MR1\"    \"F\"    \"R\"     20     NaN     NaN    NaN     NaN    1505    0.843    1.166    \"N\/A\"\n\n","truncated":false}}
%---
%[output:0a76778f]
%   data: {"dataType":"text","outputData":{"text":"          <strong>ID<\/strong>           <strong>M_F<\/strong>    <strong>Hand<\/strong>    <strong>Age<\/strong>    <strong>Educ<\/strong>    <strong>SES<\/strong>    <strong>MMSE<\/strong>    <strong>CDR<\/strong>    <strong>eTIV<\/strong>    <strong>nWBV<\/strong>      <strong>ASF<\/strong>     <strong>Delay<\/strong>\n    <strong>_______________<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>_____<\/strong>    <strong>_____<\/strong>    <strong>_____<\/strong>\n\n    \"OAS1_0001_MR1\"    \"F\"    \"R\"     74       2       3     29       0    1344    0.743    1.306    \"N\/A\"\n    \"OAS1_0002_MR1\"    \"F\"    \"R\"     55       4       1     29       0    1147     0.81    1.531    \"N\/A\"\n    \"OAS1_0003_MR1\"    \"F\"    \"R\"     73       4       3     27     0.5    1454    0.708    1.207    \"N\/A\"\n    \"OAS1_0004_MR1\"    \"M\"    \"R\"     28     NaN     NaN    NaN     NaN    1588    0.803    1.105    \"N\/A\"\n    \"OAS1_0005_MR1\"    \"M\"    \"R\"     18     NaN     NaN    NaN     NaN    1737    0.848     1.01    \"N\/A\"\n    \"OAS1_0006_MR1\"    \"F\"    \"R\"     24     NaN     NaN    NaN     NaN    1131    0.862    1.551    \"N\/A\"\n    \"OAS1_0007_MR1\"    \"M\"    \"R\"     21     NaN     NaN    NaN     NaN    1516     0.83    1.157    \"N\/A\"\n    \"OAS1_0009_MR1\"    \"F\"    \"R\"     20     NaN     NaN    NaN     NaN    1505    0.843    1.166    \"N\/A\"\n    \"OAS1_0010_MR1\"    \"M\"    \"R\"     74       5       2     30       0    1636    0.689    1.073    \"N\/A\"\n    \"OAS1_0011_MR1\"    \"F\"    \"R\"     52       3       2     30       0    1321    0.827    1.329    \"N\/A\"\n\n","truncated":false}}
%---
%[output:7b725b6c]
%   data: {"dataType":"text","outputData":{"text":"          <strong>ID<\/strong>           <strong>M_F<\/strong>    <strong>Hand<\/strong>    <strong>Age<\/strong>    <strong>Educ<\/strong>    <strong>SES<\/strong>    <strong>MMSE<\/strong>    <strong>CDR<\/strong>    <strong>eTIV<\/strong>    <strong>nWBV<\/strong>      <strong>ASF<\/strong>     <strong>Delay<\/strong>\n    <strong>_______________<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>_____<\/strong>    <strong>_____<\/strong>    <strong>_____<\/strong>\n\n    \"OAS1_0236_MR2\"    \"F\"    \"R\"     20     NaN     NaN    NaN     NaN    1222    0.872    1.436    \"3\"  \n    \"OAS1_0239_MR2\"    \"F\"    \"R\"     29     NaN     NaN    NaN     NaN    1438    0.822    1.221    \"40\" \n    \"OAS1_0249_MR2\"    \"F\"    \"R\"     28     NaN     NaN    NaN     NaN    1215    0.865    1.444    \"3\"  \n    \"OAS1_0285_MR2\"    \"M\"    \"R\"     20     NaN     NaN    NaN     NaN    1469    0.847    1.195    \"2\"  \n    \"OAS1_0353_MR2\"    \"M\"    \"R\"     22     NaN     NaN    NaN     NaN    1684     0.79    1.042    \"40\" \n    \"OAS1_0368_MR2\"    \"M\"    \"R\"     22     NaN     NaN    NaN     NaN    1580    0.856    1.111    \"89\" \n    \"OAS1_0379_MR2\"    \"F\"    \"R\"     20     NaN     NaN    NaN     NaN    1262    0.861     1.39    \"2\"  \n    \"OAS1_0395_MR2\"    \"F\"    \"R\"     26     NaN     NaN    NaN     NaN    1283    0.834    1.368    \"39\" \n\n","truncated":false}}
%---
%[output:7e9e68c8]
%   data: {"dataType":"text","outputData":{"text":"          <strong>ID<\/strong>           <strong>M_F<\/strong>    <strong>Hand<\/strong>    <strong>Age<\/strong>    <strong>Educ<\/strong>    <strong>SES<\/strong>    <strong>MMSE<\/strong>    <strong>CDR<\/strong>    <strong>eTIV<\/strong>    <strong>nWBV<\/strong>      <strong>ASF<\/strong>     <strong>Delay<\/strong>\n    <strong>_______________<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>_____<\/strong>    <strong>_____<\/strong>    <strong>_____<\/strong>\n\n    \"OAS1_0285_MR2\"    \"M\"    \"R\"     20     NaN     NaN    NaN     NaN    1469    0.847    1.195    \"2\"  \n    \"OAS1_0353_MR2\"    \"M\"    \"R\"     22     NaN     NaN    NaN     NaN    1684     0.79    1.042    \"40\" \n    \"OAS1_0368_MR2\"    \"M\"    \"R\"     22     NaN     NaN    NaN     NaN    1580    0.856    1.111    \"89\" \n    \"OAS1_0379_MR2\"    \"F\"    \"R\"     20     NaN     NaN    NaN     NaN    1262    0.861     1.39    \"2\"  \n    \"OAS1_0395_MR2\"    \"F\"    \"R\"     26     NaN     NaN    NaN     NaN    1283    0.834    1.368    \"39\" \n\n","truncated":false}}
%---
%[output:54f2ef4e]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"'table'"}}
%---
%[output:1db51d36]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"'double'"}}
%---
%[output:53cadf05]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"74"}}
%---
%[output:7f9388bd]
%   data: {"dataType":"matrix","outputData":{"columns":1,"name":"ans","rows":5,"type":"double","value":[["74"],["55"],["73"],["28"],["18"]]}}
%---
%[output:5fcdca73]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"74"}}
%---
%[output:1234a688]
%   data: {"dataType":"tabular","outputData":{"columnNames":["Hand","Age","Educ"],"columns":3,"dataTypes":["string","double","double"],"header":"5×3 table","name":"ans","rows":5,"type":"table","value":[["\"R\"","74","2"],["\"R\"","55","4"],["\"R\"","73","4"],["\"R\"","28","NaN"],["\"R\"","18","NaN"]]}}
%---
%[output:18037ba3]
%   data: {"dataType":"matrix","outputData":{"columns":3,"name":"ans","rows":1,"type":"double","value":[["74","74","74"]]}}
%---
%[output:6d3121a8]
%   data: {"dataType":"text","outputData":{"text":"          <strong>ID<\/strong>           <strong>M_F<\/strong>    <strong>Hand<\/strong>    <strong>Age<\/strong>    <strong>Educ<\/strong>    <strong>SES<\/strong>    <strong>MMSE<\/strong>    <strong>CDR<\/strong>    <strong>eTIV<\/strong>    <strong>nWBV<\/strong>      <strong>ASF<\/strong>     <strong>Delay<\/strong>\n    <strong>_______________<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>___<\/strong>    <strong>____<\/strong>    <strong>_____<\/strong>    <strong>_____<\/strong>    <strong>_____<\/strong>\n\n    \"OAS1_0065_MR1\"    \"M\"    \"R\"     90      2       3      25      0     1301    0.645    1.349    \"N\/A\"\n    \"OAS1_0083_MR1\"    \"F\"    \"R\"     90      5       3      27      0     1200    0.727    1.462    \"N\/A\"\n    \"OAS1_0221_MR1\"    \"F\"    \"R\"     94      5       1      29      0     1474    0.696     1.19    \"N\/A\"\n\n","truncated":false}}
%---
%[output:26ddb183]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"90"}}
%---
%[output:62c7ec8c]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"436"}}
%---
%[output:6143b4bb]
%   data: {"dataType":"matrix","outputData":{"columns":1,"header":"436×1 logical array","name":"ans","rows":436,"type":"logical","value":[["0"],["0"],["0"],["1"],["1"],["1"],["1"],["1"],["0"],["0"],["1"],["0"],["1"],["1"],["0"]]}}
%---
%[output:47746a9a]
%   data: {"dataType":"textualVariable","outputData":{"name":"nMissing","value":"220"}}
%---
%[output:4e987cd3]
%   data: {"dataType":"matrix","outputData":{"columns":1,"header":"436×1 logical array","name":"ans","rows":436,"type":"logical","value":[["1"],["1"],["1"],["0"],["0"],["0"],["0"],["0"],["1"],["1"],["0"],["1"],["0"],["0"],["1"]]}}
%---
%[output:020567ca]
%   data: {"dataType":"textualVariable","outputData":{"name":"nNotMissing","value":"216"}}
%---
%[output:40b3cf7a]
%   data: {"dataType":"textualVariable","outputData":{"name":"nMissing","value":"220"}}
%---
%[output:45325444]
%   data: {"dataType":"textualVariable","outputData":{"name":"nNotMissing","value":"216"}}
%---
%[output:487dda35]
%   data: {"dataType":"matrix","outputData":{"columns":1,"name":"ans","rows":5,"type":"double","value":[["1"],["2"],["3"],["4"],["5"]]}}
%---
%[output:18acbca1]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"5"}}
%---
