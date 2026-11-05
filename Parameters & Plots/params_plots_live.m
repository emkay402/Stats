%[text] # Statistical Parameters and Diagrams: applied to the OASIS-1 data
%[text] **Plan for today**
%[text] - **Parameters** to describe the data: mode, median, mean (central tendency); variance, standard deviation, standard error of the mean (dispersion)
%[text] - **Plots** to illustrate the data: bar plots (frequency); histograms and boxplots (distribution); scatterplots (relationship) \
%[text] Data: `oasis_cross-sectional.csv` (Marcus et al., 2007). Keep it in the same folder as this script.
%[text] ## 0. The data
%[text] The table has 436 rows but only 416 subjects: 20 subjects have a repeat scan session (`MR2`). Repeated rows of the same person are not independent observations, so for all descriptive statistics below we keep **one row per subject** (the first session, `MR1`).
raw = readtable("oasis_cross-sectional.csv", "TextType", "string");
T = raw(endsWith(raw.ID, "MR1"), :);
fprintf("all rows: %d | one row per subject: %d\n", height(raw), height(T));
%%
head(T)
%%
%[text] Which parameter and plot we may use depends on the **scale of measurement** of a column:
%[text] - `M_F`: sex (nominal)
%[text] - `Educ`: education level, 1 to 5 (ordinal)
%[text] - `CDR`: Clinical Dementia Rating, 0 / 0.5 / 1 / 2 (ordinal)
%[text] - `Age`: age in years (equal-interval)
%[text] - `eTIV`: estimated total intracranial volume in mm^3 (equal-interval)
%[text] - `nWBV`: normalized whole-brain volume (equal-interval)
%[text] - `MMSE`: cognitive screening score, 0 to 30 (a point score, usually treated as equal-interval) \
%[text] `Educ`, `CDR` and `MMSE` are only available for about half of the participants (mostly the older ones), so the sample size differs between columns:
numVars = ["Educ", "CDR", "Age", "eTIV", "nWBV", "MMSE"];
array2table(sum(~isnan(T{:, numVars})), "VariableNames", numVars)
%%
%[text] ## 0.1 Mapping Text to Numbers
%[text] Many analyses need numbers instead of text. We use a dictionary (key -\> value). For example: the nominal variable |M\_F|, with M -\> 0 and F -\> 1. We can inspect the different values a variable can take on by inspecting its unique elements:
rmmissing(unique(T.M_F))
M_F_map = dictionary(["M", "F"], [0, 1])
%[text] We can add a new column, M\_F\_map, that consists of our new mapping:
T.M_F_map = M_F_map(T.M_F);
T(1:8, ["M_F", "M_F_map"])
%[text] ## 1. Statistical Parameters
%[text] ## 1.1 Mode
%[text] The **mode** is the value found most often in the data. It is useful for nominal data, but can always be used.
%[text] To find it, we transform the data into a **frequency table**. In OASIS we can consider the nominal column `M_F` (sex) and the ordinal columns `Educ` and `CDR`.
groupcounts(T, "M_F")
%%
groupcounts(T, "CDR")
%[text] The |NaN| row counts the participants without a rating (missing values).
%%
fprintf("Educ: mode = %g\n", mode(rmmissing(T.Educ)));
fprintf("CDR:  mode = %g\n", mode(rmmissing(T.CDR)));
%%
%[text] A column can have **more than one mode**, and for continuous data the mode is usually not informative: with many different values, almost every value occurs only once.
[~, freq, allModes] = mode(T.eTIV);
fprintf("eTIV has %d 'modes', each occurring %d times in %d participants\n", numel(allModes{1}), freq, height(T));
allModes{1}
%%
%[text] ## 1.2 Median
%[text] The **median** splits the **ordered** data into a lower and a higher 50%. The number of values above and below the median is exactly the same. It needs at least **ordinal** data.
%[text] In OASIS: `Educ` is ordinal, so the median is allowed (the mean would not be). `Age` is shown for comparison.
median(T.Educ, "omitnan")
%%
median(T.Age)
%%
%[text] The median `Educ` of 3 means "some college": half of the assessed participants have at most some college, half have at least that.
%[text] ## 1.3 Mean
%[text] The **arithmetic mean** is the sum of all values divided by the number of samples $N$:
%[text]{"align":"center"} $\\bar{x} = \\frac{1}{N}\\sum\_{i=1}^{N} x\_i$
%[text] It is only really sensible for **equal-interval** data.
col = "Age";
manual  = sum(T{:, col}) / height(T);
builtin = mean(T{:, col});
table(col, manual, builtin)
%%
%[text] ## 1.4 Comparison of median and mean
%[text] The relation between mean and median tells us about the **shape of the distribution**:
%[text] - symmetric distribution: mean ~ median
%[text] - left-skewed (long tail to low values): mean \< median
%[text] - right-skewed (long tail to high values): mean \> median \
%[text] OASIS examples:
%[text] - `eTIV`: roughly symmetric
%[text] - `MMSE`: left-skewed, because most participants score close to the maximum of 30 and a few score much lower
%[text] - `30 - MMSE` ("points lost"): the mirrored version, hence right-skewed \
mmse = rmmissing(T.MMSE);
examples = {T.eTIV, mmse, 30 - mmse};
titles   = ["roughly symmetric", "left-skewed", "right-skewed"];
xlabels  = ["eTIV (mm^3)", "MMSE score", "points lost (30 - MMSE)"];

figure
tiledlayout(1, 3);
for i = 1:3
    x = examples{i};
    nexttile
    histogram(x, 20, "FaceColor", [0.8 0.8 0.8], "EdgeColor", "w")
    hold on
    h1 = xline(mean(x), "r--", "LineWidth", 2);
    h2 = xline(median(x), "g-", "LineWidth", 2);
    hold off
    legend([h1 h2], ["mean = " + string(round(mean(x), 2)), "median = " + string(round(median(x), 2))], ...
        "Location", "northwest")
    title(titles(i)); xlabel(xlabels(i)); ylabel("Number of participants")
end
%%
%[text] Skewness: positive = right-skewed, negative = left-skewed.
skew = @(x) mean((x - mean(x)).^3) / std(x, 1)^3;
table(titles', cellfun(@numel, examples)', cellfun(@mean, examples)', cellfun(@median, examples)', ...
    cellfun(skew, examples)', VariableNames=["Distribution", "n", "Mean", "Median", "Skewness"])
%%
%[text] **Caution:** mean and median can also agree when *neither* describes the data well. `Age` has a mean and a median in the middle of the range, but there are hardly any participants there: the sample consists of two clusters, young adults and older adults.
figure
histogram(T.Age, 15:5:100, "FaceColor", [0.8 0.8 0.8], "EdgeColor", "w")
hold on
h1 = xline(mean(T.Age), "r--", "LineWidth", 2);
h2 = xline(median(T.Age), "g-", "LineWidth", 2);
hold off
legend([h1 h2], ["mean = " + string(round(mean(T.Age), 1)), "median = " + string(round(median(T.Age), 1))])
xlabel("Age (years)"); ylabel("Number of participants")
%%
%[text] ## 1.5 When to use mode, median and mean
%[text] Each parameter requires a different minimum scale of measurement:
%[text] - nominal (`M_F`, `Hand`): mode
%[text] - ordinal (`Educ`, `SES`, `CDR`): mode, median
%[text] - equal-interval (`Age`, `eTIV`, `nWBV`, and `MMSE`): mode, median, mean \
%[text] **Always use the mean for equal-interval data? No!** Consider **outliers**. A few participants with low `MMSE` scores pull the **mean** down, while the **median** stays close to where most of the participants are.
fprintf("MMSE: mean = %.2f, median = %.1f, n = %d\n", mean(mmse), median(mmse), numel(mmse));
fprintf("share of participants with the maximum score of 30: %.0f%%\n", 100 * mean(mmse == 30));
%%
%[text] ## 1.6 Variance
%[text] The **variance** is a measure of dispersion: it quantifies how much every individual value deviates from the mean. It needs at least equal-interval data.
%[text] Why the square? Positive and negative deviations from the mean would otherwise cancel each other out.
%[text] **Population variance** (the whole population is known, we divide by $N$):
%[text]{"align":"center"} $\\sigma^2 = \\frac{1}{N}\\sum\_{i=1}^{N}(x\_i-\\mu)^2$
%[text] **Sample variance** (we only know a sample and estimate the population, we divide by $N-1$):
%[text]{"align":"center"} $s^2 = \\frac{1}{N-1}\\sum\_{i=1}^{N}(x\_i-\\bar{x})^2$
%[text] **Watch out:** libraries differ in their default! In MATLAB, `var` divides by $N-1$ unless you tell it otherwise (Python's NumPy divides by $N$, pandas by $N-1$).
x = mmse(1:10);    % taking 10 values as an example
fprintf("var(x)    (divide by N-1): %.2f\n", var(x));
fprintf("var(x, 0) (divide by N-1): %.2f\n", var(x, 0));
fprintf("var(x, 1) (divide by N)  : %.2f\n", var(x, 1));
fprintf("by hand, sum of squares / N: %.2f\n", sum((x - mean(x)).^2) / numel(x));
%%
%[text] ## Why N-1? The sample variance correctly estimates the population variance
%[text] Simulation: we pretend that the 416 `eTIV` values *are* the population. We draw many random samples of size $n$ and compute the variance of every sample by dividing by $N$, $N-1$ and $N-2$. If a formula estimates the population variance well, its average over many samples should match the true value.
rng(42)                                   % fixed seed: same result every time
population = T.eTIV;
trueVar = var(population, 1);             % population variance (divide by N)

ns = [3 5 10 30 100];
divN = zeros(size(ns)); divN1 = zeros(size(ns)); divN2 = zeros(size(ns));
for k = 1:numel(ns)
    n = ns(k);
    samples = population(randi(numel(population), 10000, n));    % 10,000 samples of size n
    s_sq = sum((samples - mean(samples, 2)).^2, 2);                % sum of squares of each sample
    divN(k)  = mean(s_sq / n);
    divN1(k) = mean(s_sq / (n - 1));
    divN2(k) = mean(s_sq / (n - 2));
end
fprintf("true (population) variance: %.0f\n", trueVar);
table(ns', divN', divN1', divN2', VariableNames=["n", "divide_by_N", "divide_by_N_minus_1", "divide_by_N_minus_2"])
%%
figure
semilogx(ns, divN, "o-", ns, divN1, "s-", ns, divN2, "d-", ns, repmat(trueVar, size(ns)), "k:", "LineWidth", 1.5)
legend(["divide by N", "divide by N - 1", "divide by N - 2", "true variance"], "Location", "southeast")
xlabel("Sample size n (log scale)"); ylabel("Average estimated variance")
%%
%[text] Dividing by $N$ underestimates the variance, and the smaller the sample, the larger the error. Dividing by $N-1$ corrects for this: on average it hits the true value. Dividing by $N-2$ overshoots.
%[text] ## 1.7 Standard deviation
%[text] The variance is in **squared units** (mm^6 for `eTIV`!), which is hard to interpret. The **standard deviation** is its square root, and is back in the original units. It also needs equal-interval data.
%[text]{"align":"center"} $s = \\sqrt{s^2} \\qquad\\qquad \\sigma = \\sqrt{\\sigma^2}$
cols = ["Age", "eTIV"];
units = ["years"; "mm^3"];
table(cols', units, mean(T{:, cols})', var(T{:, cols})', std(T{:, cols})', ...
    VariableNames=["Column", "Unit", "Mean", "Variance", "SD"])
%%
%[text] Check: the SD is the square root of the variance.
sqrt(var(T{:, cols}))
%%
%[text] ## 1.8 Standard error of the mean
%[text] The **standard error of the mean (SEM)** quantifies how closely the *sample mean* represents the *population mean*:
%[text]{"align":"center"} $SEM = \\frac{s}{\\sqrt{N}}$
%[text] It usually decreases with increasing sample size: the larger the sample, the better we estimate the "true" population value. (MATLAB has no built-in function for it, so we compute it ourselves.)
x = T.nWBV;
sem = std(x) / sqrt(numel(x))
%%
%[text] Effect of sample size: we draw random subsamples of different sizes from `nWBV` and compute their SEM.
sizes = [5 10 20 50 100 200 numel(x)];
observed = zeros(size(sizes));
for k = 1:numel(sizes)
    s = x(randperm(numel(x), sizes(k)));      % random subsample without replacement
    observed(k) = std(s) / sqrt(sizes(k));
end
expected = std(x) ./ sqrt(sizes);

figure
plot(sizes, expected, "-", "Color", [0.5 0.5 0.5], "LineWidth", 1.5)
hold on
plot(sizes, observed, "o", "MarkerFaceColor", [0 0.45 0.74])
hold off
legend(["s / sqrt(N) of the full sample", "SEM of one random subsample"])
xlabel("Sample size N"); ylabel("SEM of nWBV")
%%
%[text] SEM of `nWBV` per dementia rating, which we will need again for the error bars in the bar plot. The numbers show the difference between the parameters: **SD** describes the spread of the *participants*, **SEM** the precision of the *mean*.
G = groupsummary(T, "CDR", {"mean", "std"}, "nWBV");
G = G(~isnan(G.CDR), :);                         % drop the participants without a rating
G.SEM_nWBV = G.std_nWBV ./ sqrt(G.GroupCount);
G(:, ["CDR", "GroupCount", "mean_nWBV", "std_nWBV", "SEM_nWBV"])
% Note the group |CDR = 2| with only two participants: its SD and SEM are not meaningful.
%%
%[text] ## 1.9 Take-home messages
%[text] - **Mean and variance** are the two main parameters that describe a distribution (technically also its shape).
%[text] - The **variance** is the "primal" value, the **standard deviation** is the interpretable one (same units as the data).
%[text] - Variance and SD describe the dispersion of the *observations*. The **SEM** is attached to a statistical parameter (usually the mean) and describes how well that parameter represents the population value.
%[text] - The SEM divides by $\\sqrt{N}$ because the SD is the square root of an already squared quantity: the units have to match. \
%[text] ## 2. Diagrams
%[text] ## 2.1 Bar plots
%[text] Bar plots display **frequencies or percentages of discrete variables**. Example: how many participants are in each dementia rating (`CDR`)?
cdr = rmmissing(T.CDR);
[counts, levels] = groupcounts(cdr);
pct = 100 * counts / sum(counts);

figure
tiledlayout(1, 2);
nexttile
bar(counts)
nexttile
bar(pct)
%%
%[text] Without labels, nobody knows what this shows: **label the axes!**
xl = string(levels);                       % "0" "0.5" "1" "2"
figure
tiledlayout(1, 2);

nexttile
b = bar(categorical(xl, xl), counts);
text(b.XEndPoints, b.YEndPoints, string(counts), "HorizontalAlignment", "center", "VerticalAlignment", "bottom")
xlabel("Clinical Dementia Rating (CDR)"); ylabel("Number of participants")

nexttile
b = bar(categorical(xl, xl), pct);
text(b.XEndPoints, b.YEndPoints, compose("%.1f%%", pct), "HorizontalAlignment", "center", "VerticalAlignment", "bottom")
xlabel("Clinical Dementia Rating (CDR)"); ylabel("Percentage of assessed participants")
%%
%[text] Bar plots are also used for **means**. Then we need **error bars** that show the uncertainty of the mean. Here: mean `nWBV` per `CDR` group, with the SEM as error bars (from section 1.8).
xl4 = "CDR " + string(G.CDR) + newline + "(n=" + string(G.GroupCount) + ")";

figure
bar(1:4, G.mean_nWBV, "FaceColor", [0 0.45 0.74])
hold on
errorbar(1:4, G.mean_nWBV, G.SEM_nWBV, "Color", "k", "LineStyle", "none", "LineWidth", 1.5, "CapSize", 10)
hold off
xticks(1:4); xticklabels(xl4)
ylabel("Mean normalized whole-brain volume (\pm SEM)")
%%
%[text] **Wait... does a bar plot really make sense for continuous data?** A bar plot reduces each group to one number. Different distributions can give the same bar. Compare the same data as (1) bars with error bars, (2) bars with the individual participants, (3) a boxplot:
A = T(~isnan(T.CDR), :);
grp = findgroups(A.CDR);

figure
tiledlayout(1, 3);

nexttile
bar(1:4, G.mean_nWBV, "FaceColor", [0.8 0.8 0.8])
hold on
errorbar(1:4, G.mean_nWBV, G.SEM_nWBV, "Color", "k", "LineStyle", "none", "LineWidth", 1.5, "CapSize", 10)
hold off
title("bars \pm SEM"); xticks(1:4); xticklabels(xl4); ylim([0 0.9]); ylabel("Normalized whole-brain volume")

nexttile
bar(1:4, G.mean_nWBV, "FaceColor", [0.8 0.8 0.8])
hold on
swarmchart(grp, A.nWBV, 8, "filled", "MarkerFaceAlpha", 0.6)
hold off
title("bars + individual participants"); xticks(1:4); xticklabels(xl4); ylim([0 0.9])

nexttile
boxchart(grp, A.nWBV)
title("boxplot"); xticks(1:4); xticklabels(xl4); ylim([0 0.9])
%%
%[text] The bars hide the distribution, the group sizes (note again `CDR 2`!) and any outliers. For continuous data, prefer plots that show the distribution itself: histograms, boxplots, or raincloud plots (see homework).
%[text] ## 2.2 Histograms
%[text] A histogram is similar to a bar plot, but for **continuous values**. It plots the distribution in bins. **You** decide how fine-grained the representation is by choosing the number of bins, so the same data can look very different:
histCols = ["Age", "nWBV"];
histLabels = ["Age (years)", "Normalized whole-brain volume"];
binsList = [5 15 40];

figure
tiledlayout(2, 3);
for r = 1:2
    for k = 1:3
        nexttile
        histogram(T.(histCols(r)), binsList(k), "FaceColor", [0 0.45 0.74], "EdgeColor", "w")
        title(binsList(k) + " bins")
        xlabel(histLabels(r)); ylabel("Number of participants")
    end
end
%%
%[text] With 5 bins the picture is very coarse: the sharp peak in the early twenties disappears inside the first bar. With 15 bins the peak, the dip in between and the cluster of older participants are all visible. With 40 bins the plot becomes jagged. A good bin size shows the overall shape without too much noise.
%[text] ## 2.3 Boxplots
%[text] A boxplot shows several parameters at once:
%[text] - minimum and maximum value
%[text] - the quarters of the data (including the median)
%[text] - outliers \
%[text] The distance between the 1st and 3rd quartile is the **interquartile range (IQR)**. Values far away from the box are flagged as outliers:
%[text] - **strict criterion:** more than 1.5 x IQR below Q1 / above Q3
%[text] - **liberal criterion:** more than 3 x IQR below Q1 / above Q3 \
%[text] **Computing it by hand** for `MMSE`:
q = quantile(mmse, [0.25 0.5 0.75]);
q1 = q(1); med = q(2); q3 = q(3);
IQRange = q3 - q1;

table(min(mmse), q1, med, q3, max(mmse), max(mmse) - min(mmse), IQRange, ...
    "VariableNames", ["Min", "Q1", "Median", "Q3", "Max", "Range", "IQR"])
%%
for k = [1.5 3]
    lower = q1 - k * IQRange;
    upper = q3 + k * IQRange;
    nOut = sum(mmse < lower | mmse > upper);
    fprintf("%.1f x IQR: fences at %.1f and %.1f -> %d outliers\n", k, lower, upper, nOut);
end
%%
%[text] The same data has outliers under the strict criterion and none under the liberal one: "outlier" depends on the rule you choose. Report which one you used. `boxchart` uses the strict criterion; the dashed lines show both lower fences.
figure
boxchart(mmse)
yline(q1 - 1.5 * IQRange, "r--", "strict fence (1.5 x IQR)");
yline(q1 - 3 * IQRange, "b--", "liberal fence (3 x IQR)");
xticks([]); ylabel("MMSE score")
%%
%[text] ## 2.4 Scatterplots
%[text] Scatterplots show the **relationship between two continuous, equal-interval variables**. Every point is one participant, and its coordinates are the scores on the two variables.
%[text] Brain volume shrinks with age, and more strongly in dementia:
levelsCDR = [0 0.5 1 2];
colors = [0 0.45 0.74; 0.85 0.33 0.10; 0.80 0.15 0.15; 0 0 0];

figure
hold on
unassessed = T(isnan(T.CDR), :);
scatter(unassessed.Age, unassessed.nWBV, 14, [0.8 0.8 0.8], "filled", "DisplayName", "CDR not assessed")
for i = 1:4
    sub = T(T.CDR == levelsCDR(i), :);
    scatter(sub.Age, sub.nWBV, 16, colors(i, :), "filled", "MarkerFaceAlpha", 0.8, ...
        "DisplayName", "CDR " + string(levelsCDR(i)))
end
hold off
xlabel("Age (years)"); ylabel("Normalized whole-brain volume")
legend("Location", "northeast")
%%
%[text] `nWBV` decreases with `Age`, and the participants with dementia are among the older ones with lower volumes. How to quantify such relationships is the topic of the next sessions (correlation and regression).
%[text] ## 2.5 Raincloud plots
%[text] Raincloud plots (Allen et al., 2021) combine three views of the same data, so nothing is hidden:
%[text] - the **cloud**: the shape of the distribution (a smoothed density estimate), drawn above
%[text] - the **box**: the summary (median and quartiles), in the middle
%[text] - the **rain**: every individual data point, drawn below \
%[text] There is no built-in raincloud plot in MATLAB.
%[text] ## Summary
%[text] - most frequent value (any scale): mode, frequency table, bar plot
%[text] - middle of the data (ordinal or higher): median, boxplot
%[text] - average (equal-interval): mean, sensitive to outliers and skew
%[text] - spread of the observations: variance, standard deviation
%[text] - precision of the mean: standard error of the mean
%[text] - shape of a continuous distribution: histogram, boxplot, raincloud plot
%[text] - relationship of two continuous variables: scatterplot \
%[text] **Sources**
%[text] - Marcus, D. S. et al. (2007). Open Access Series of Imaging Studies (OASIS): Cross-sectional MRI data in young, middle aged, nondemented, and demented older adults. *Journal of Cognitive Neuroscience, 19*, 1498-1507.
%[text] - Allen, M., Poggiali, D., Whitaker, K. et al. (2021). Raincloud plots: a multi-platform tool for robust data visualization. *Wellcome Open Research, 4*:63. \

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
