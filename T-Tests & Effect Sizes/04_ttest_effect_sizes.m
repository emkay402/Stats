%[text] # t-Test and Effect Sizes: applied to the OASIS-1 data
%[text] 
%[text] - **0. Data and toolbox**
%[text] - **1. Hypothesis testing:** H0 and H1, directed and undirected, $\\alpha$ and $\\beta$ errors
%[text] - **2. How do we get the p-value?** distribution of differences under H0, t, critical values
%[text] - **3. Three kinds of t-test:** independent, dependent, single group
%[text] - **4. Assumptions:** Q-Q plot, quantitative tests of normality, equal variances
%[text] - **5. Power**
%[text] - **6. Effect sizes:** why a p-value is not enough, Cohen's $d$, $\\eta^2$ and $\\omega^2$
%[text] - **7. Reporting and summary** \
%[text] Data: `oasis_cross-sectional_MR1.csv` (Marcus et al., 2007), which contains *only the first session (MR1)* of every subject. Keep it in the same folder as this script.
%[text] 
%[text] ## 0. The data
%[text] From this week on we load a file with **one row per subject**, so we no longer have to filter out the repeat sessions ourselves. This also means that the file contains *no repeated measurements*. We keep this in mind for the dependent t-test.
%[text] Two columns carry this session:
%[text] - `eTIV`: estimated total intracranial volume (head size). Men have larger heads on average: a **large** effect.
%[text] - `Age`: age in years. The age difference between the sexes is small: a **small** effect. \
rng(42)                                           % fixed seed: simulations give the same result every time
T = readtable("oasis_cross-sectional_MR1.csv", "TextType", "string");
assert(height(T) == 416, "Expected 416 participants (one row per subject).")
isM = T.M_F == "M";                               % logical index: men

etivM = T.eTIV(isM);   etivF = T.eTIV(~isM);      % head size of men and women
ageM  = T.Age(isM);    ageF  = T.Age(~isM);       % age of men and women
nM = numel(etivM);     nF = numel(etivF);

summary = table(["men"; "women"], [nM; nF], [mean(etivM); mean(etivF)], [std(etivM); std(etivF)], ...
                [mean(ageM); mean(ageF)], [std(ageM); std(ageF)], ...
                VariableNames=["Group", "n", "eTIV_mean", "eTIV_SD", "Age_mean", "Age_SD"])
%%
%[text] ## 1. Hypothesis testing
%[text] 
%[text] ## 1.1 H0, H1, and the two kinds of error
%[text] A hypothesis test starts from two competing statements about the population:
%[text] - **H0 (null hypothesis):** there is no difference ($\\mu\_1 = \\mu\_2$).
%[text] - **H1 (alternative hypothesis):** there is a difference. *Undirected:* $\\mu\_1 \\neq \\mu\_2$ (two-sided). *Directed:* $\\mu\_1 \> \\mu\_2$ or $\\mu\_1 \< \\mu\_2$ (one-sided). The direction must be decided **before** looking at the data. \
%[text] We assume H0 is true and ask: *how likely are data at least this extreme if there were no difference?* That probability is the **p-value**. If $p \< \\alpha$ (conventionally .05), we reject H0.
%[text] Because we decide on a sample, we can be wrong in two ways:
%[text] - **we keep H0, and H0 is true:** correct decision ($1-\\alpha$)
%[text] - **we keep H0, but H1 is true:** beta **error** (type II): we miss a real effect
%[text] - **we reject H0, but H0 is true:** alpha **error** (type I): a false alarm
%[text] - **we reject H0, and H1 is true:** correct decision, the **power** ($1-\\beta$) \
%[text] In real data we never see the truth, but in a simulation we choose it. We run 10,000 experiments with 30 per group: once with **no** true difference, once with a true difference of half a standard deviation ($d = 0.5$). (`ttest2` tests every column of a matrix separately, so one call runs all 10,000 experiments.)
reps = 10000;  n = 30;
a  = randn(n, reps);                  % group 1: mean 0
b0 = randn(n, reps);                  % H0 true: group 2 has the same mean
b1 = randn(n, reps) + 0.5;            % H1 true: group 2 is 0.5 SD higher
[~, p0] = ttest2(a, b0);
[~, p1] = ttest2(a, b1);

alphaRate = mean(p0 < 0.05);          % share of false alarms
powerRate = mean(p1 < 0.05);          % share of detected effects

rates = table([1 - alphaRate; alphaRate], [1 - powerRate; powerRate], ...
              VariableNames=["H0_true", "H1_true"], RowNames=["keep H0", "reject H0"])
fprintf("alpha error: %.3f | beta error: %.3f | power: %.3f\n", alphaRate, 1 - powerRate, powerRate);
%%
%[text] **Reading the table:** in the left column nothing is going on, and we still reject H0 in about 5% of the experiments. That is what $\\alpha = .05$ *means*. In the right column there *is* a real effect, but with only 30 per group we miss it about every second time. The power is far below the usual 80%: see section 5.
%[text] 
%[text] ## 2. How do we get the p-value?
%[text] 
%[text] ## 2.1 The distribution of differences under H0, built by shuffling
%[text] The steps: (1) compute the difference of the group means $D = \\bar{x}\_1 - \\bar{x}\_2$. (2) If H0 is true, $D$ varies around 0 from sample to sample. (3) Standardize: $t = \\frac{D}{SE(D)}$. (4) Compare $t$ with the t distribution.
%[text] First the intuition, without any formula. If H0 is true, the labels "M" and "F" mean nothing, so we can **shuffle** them and compute $D$ every time. We use `Age` for this, because the age difference between the sexes is small: shuffled data are then a fair picture of "H0 is true".
Dobs = mean(ageM) - mean(ageF);                   % observed difference in mean age
Dnull = zeros(10000, 1);
for i = 1:10000
    shuffled = T.Age(randperm(height(T)));        % shuffle: the sex labels become meaningless
    Dnull(i) = mean(shuffled(1:nM)) - mean(shuffled(nM+1:end));
end
pPerm = mean(abs(Dnull) >= abs(Dobs));            % undirected: extremes on both sides

figure
histogram(Dnull, 60, "Normalization", "pdf", "FaceColor", [0.5 0.5 0.5])
xline(Dobs, "-", "observed D", "Color", [0.84 0.37 0], "LineWidth", 2);
xline(-Dobs, "--", "mirrored", "Color", [0.84 0.37 0], "LineWidth", 2);
xlabel("Difference of mean age, men - women (years)"); ylabel("Density")
fprintf("observed D = %.2f years | share of shuffles at least as extreme (two-sided): %.3f\n", Dobs, pPerm);
%%
%[text] The shuffled differences form a bell shape around 0. The dashed line mirrors the observed difference, because in an **undirected** test extremes on *both* sides count. The share beyond the two lines is a p-value.
%[text] 
%[text] ## 2.2 The same with the t distribution
%[text] Now the formula route: pooled SD, standard error, $t$, and the p-value from the t distribution (`tcdf`):
%[text]{"align":"center"} $s\_{pooled} = \\sqrt{\\frac{(n\_1-1)s\_1^2 + (n\_2-1)s\_2^2}{n\_1+n\_2-2}} \\qquad SE = s\_{pooled}\\sqrt{\\frac{1}{n\_1}+\\frac{1}{n\_2}} \\qquad t = \\frac{D}{SE} \\qquad df = n\_1+n\_2-2$
df = nM + nF - 2;
sp = sqrt(((nM - 1) * var(ageM) + (nF - 1) * var(ageF)) / df);
se = sp * sqrt(1 / nM + 1 / nF);
t  = Dobs / se;
pByHand = 2 * tcdf(-abs(t), df);                  % both tails

[~, pToolbox, ~, st] = ttest2(ageM, ageF);        % the ready-made function
fprintf("by hand:  t(%d) = %.3f, p = %.3f\n", df, t, pByHand);
fprintf("ttest2:   t(%d) = %.3f, p = %.3f\n", st.df, st.tstat, pToolbox);
%%
%[text] Both routes agree, and the p-value from shuffling is close to them.
%[text] 
%[text] ## 2.3 The t distribution and the critical value
%[text] The t distribution looks like a normal distribution, but has heavier tails when $df$ is small. With a growing $df$ it converges to the normal distribution.
x = linspace(-4.5, 4.5, 400);
figure
plot(x, normpdf(x), "k", "LineWidth", 1.5)
hold on
plot(x, tpdf(x, 2), "LineWidth", 1.5)
plot(x, tpdf(x, 5), "LineWidth", 1.5)
plot(x, tpdf(x, 30), "LineWidth", 1.5)
hold off
legend(["normal", "t, df = 2", "t, df = 5", "t, df = 30"], "Box", "off")
xlabel("t"); ylabel("Density")
%%
%[text] The **critical value** is the $t$ that cuts off the share $\\alpha$ in the tail(s) (`tinv` is the inverse of `tcdf`):
%[text] - directed test: $\\alpha$ in *one* tail, so $t\_{crit}$ = `tinv(1 - alpha, df)`
%[text] - undirected test: $\\alpha/2$ in *each* tail, so $t\_{crit}$ = `tinv(1 - alpha/2, df)` \
%[text] The same $\\alpha$ gives a *smaller* critical value for the directed test: it rejects H0 more easily. That is why the direction must be fixed *before* looking at the data.
dfs = [5; 10; 30; 100; 414];
critical = table(dfs, tinv(0.95, dfs), tinv(0.975, dfs), VariableNames=["df", "directed", "undirected"])
fprintf("normal distribution: directed %.3f | undirected %.3f\n", norminv(0.95), norminv(0.975));
%[text] 
%[text] ## 3. Three kinds of t-test
%[text] - **independent** (two different groups): do the groups differ? Example today: head size of men vs. women (data)
%[text] - **dependent / paired** (the same people twice): do they differ between two conditions? Example: depression score before vs. after treatment (slides)
%[text] - **single group:** does one group differ from a *given* value? Example: mean head size vs. a reference value (data) \
%[text] 
%[text] ## 3.1 Independent samples: eTIV of men vs. women
%[text] H0: $\\mu\_{men} = \\mu\_{women}$; H1: $\\mu\_{men} \\neq \\mu\_{women}$ (undirected).
figure
histogram(etivF, 20, "FaceAlpha", 0.6)
hold on
histogram(etivM, 20, "FaceAlpha", 0.6)
hold off
legend(["women (n = " + nF + ")", "men (n = " + nM + ")"], "Box", "off")
xlabel("eTIV (mm^3)"); ylabel("Number of participants")
%%
[~, p, ci, st] = ttest2(etivM, etivF);                              % classic t-test: equal variances assumed
[~, pW, ~, stW] = ttest2(etivM, etivF, "Vartype", "unequal");       % Welch: no equal-variance assumption
fprintf("classic: t(%d) = %.2f, p = %.2g\n", st.df, st.tstat, p);
fprintf("Welch:   t(%.1f) = %.2f, p = %.2g\n", stW.df, stW.tstat, pW);
fprintf("mean difference (men - women): %.0f mm^3, 95%% CI [%.0f, %.0f]\n", mean(etivM) - mean(etivF), ci(1), ci(2));
%%
%[text] Men have a clearly larger mean `eTIV`, the p-value is tiny, and we reject H0. The classic and the Welch version hardly differ here; section 4.4 shows when it matters.
%[text] **Directed version.** Suppose that, *before* looking at the data, we had predicted that men have the larger head. The alternative is then "men \> women" (`"Tail", "right"`):
[~, pDir] = ttest2(etivM, etivF, "Tail", "right");
fprintf("directed p = %.2g | undirected p / 2 = %.2g\n", pDir, (p / 2));
%[text] 
%[text] ## 3.2 Dependent samples: before and after treatment (example from the slides)
%[text] The MR1 file contains each person only once, so the data cannot show a dependent t-test. We use the situation from the slides: the same patients measured **before and after a treatment**. The numbers are **simulated** (not OASIS data).
%[text] A paired t-test is a **single-group t-test on the differences**. Every person is their own control, so differences *between* people drop out.
nPat = 20;
before = round(24 + 6 * randn(nPat, 1));          % depression score before treatment
after  = round(before - (4 + 3 * randn(nPat, 1)));% most improve, with individual variation

figure
plot([zeros(1, nPat); ones(1, nPat)], [before'; after'], "Color", [0.6 0.6 0.6])   % one line per person
hold on
scatter(zeros(nPat, 1), before, 25, "filled")
scatter(ones(nPat, 1), after, 25, "filled")
hold off
xlim([-0.3 1.3]); xticks([0 1]); xticklabels(["before", "after"]); ylabel("Depression score (simulated)")
%%
[~, pPair, ~, stPair] = ttest(before, after);                 % paired t-test
[~, pDiff, ~, stDiff] = ttest(before - after);                % one-sample t-test on the differences
[~, pWrong, ~, stWrong] = ttest2(before, after);              % WRONG here: treats the people as two groups
fprintf("paired:                 t(%d) = %.2f, p = %.2g\n", stPair.df, stPair.tstat, pPair);
fprintf("one-sample on diffs:    t(%d) = %.2f, p = %.2g   (identical)\n", stDiff.df, stDiff.tstat, pDiff);
fprintf("wrongly as independent: t(%d) = %.2f, p = %.2g\n", stWrong.df, stWrong.tstat, pWrong);
%%
%[text] The paired test equals the one-sample test on the differences. Treating the same people as two independent groups throws away the pairing: the $t$ is smaller and the $p$ larger. The paired design has *more power* whenever a person scores similarly in both conditions.
%[text] 
%[text] ## 3.3 Single group: eTIV vs. a reference value
%[text] Here we compare one sample mean with a *given constant* $\\mu\_0$. The value below is **made up** for the example (it is not an official norm): a colleague claims that the average head size of adults is 1500 mm^3.
%[text] H0: $\\mu = 1500$; H1: $\\mu \\neq 1500$.
mu0 = 1500;
[~, p1s, ci1, st1] = ttest(T.eTIV, mu0);
fprintf("mean = %.0f, SEM = %.1f\n", mean(T.eTIV), std(T.eTIV) / sqrt(height(T)));
fprintf("t(%d) = %.2f, p = %.3f\n", st1.df, st1.tstat, p1s);
fprintf("95%% CI of the mean: [%.0f, %.0f]\n", ci1(1), ci1(2));
%%
%[text] 1500 lies outside the confidence interval, which gives the same decision as the test at $\\alpha = .05$. The standard error is the same SEM we used for confidence intervals last week.
%[text] 
%[text] ## 4. Assumptions of the t-test
%[text] The classic t-test assumes:
%[text] 1. the dependent variable is measured on an **interval scale**
%[text] 2. the values are **normally distributed** (within each group)
%[text] 3. the **variances** of the groups are equal (independent test)
%[text] 4. the observations are **independent** and come from a random sample \
%[text] Assumptions 1 and 4 come from the study design. Assumptions 2 and 3 we can check in the data.
%[text] 
%[text] ## 4.1 The Q-Q plot, step by step
%[text] A **Q-Q plot** (quantile-quantile plot) compares *every* value with what a normal distribution would give, and does not depend on bin widths. The recipe:
%[text] 1. **sort** the data from smallest to largest
%[text] 2. give the $i$-th value its **share of the data** up to it: $(i - 0.5)/n$ (the $-0.5$ keeps the first and last value away from 0 and 1, where the normal distribution would give $\\pm\\infty$)
%[text] 3. look up the **z-value** that has this share in a standard normal distribution (`norminv`): the *expected* z-value if the data were normal
%[text] 4. plot the expected z-value (x-axis) against the observed value (y-axis)
%[text] 5. add the line of a perfectly normal variable with the same mean and SD \
%[text] If the data are normal, the points fall on the line. For the head size of the women:
x = etivF;
n = numel(x);
observed = sort(x);                               % 1. sort
prob = ((1:n)' - 0.5) / n;                        % 2. share of the data up to each rank
expectedZ = norminv(prob);                        % 3. expected z-value

table((1:5)', observed(1:5), prob(1:5), expectedZ(1:5), VariableNames=["Rank", "Observed_eTIV", "Share", "Expected_z"])
%%
figure
tiledlayout(1, 2);
nexttile
scatter(expectedZ, observed, 10, "filled", "MarkerFaceAlpha", 0.7)               % 4. plot
hold on
plot(expectedZ, mean(x) + std(x) * expectedZ, "k", "LineWidth", 1.5)             % 5. normal line
hold off
xlabel("Expected z-value if normal"); ylabel("Observed eTIV (mm^3)"); title("women")

x = etivM;  n = numel(x);
nexttile
scatter(norminv(((1:n)' - 0.5) / n), sort(x), 10, "filled", "MarkerFaceAlpha", 0.7)
hold on
plot(norminv(((1:n)' - 0.5) / n), mean(x) + std(x) * norminv(((1:n)' - 0.5) / n), "k", "LineWidth", 1.5)
hold off
xlabel("Expected z-value if normal"); title("men")
%%
%[text] In both groups the bulk of the points lies on the line; only a few extreme values at the ends drift off it. Tails are where single extreme values have the most influence. By eye, `eTIV` is approximately normal **within each sex**.
%[text] **The toolbox does the same in one line:** `qqplot(x)`. It uses the same points, but draws its reference line through the first and third quartile (which is less affected by extreme values than the mean and SD). Now two cases that look different: all participants pooled (a mixture of two groups), and `nWBV` (normalized brain volume):
figure
tiledlayout(1, 2);
nexttile
qqplot(T.eTIV)
title("eTIV, all participants pooled")
nexttile
qqplot(T.nWBV)
title("nWBV, all participants")
%%
%[text] Pooled `eTIV` looks a little worse in the tails than within each sex, but the mixture effect is subtle here, because the group means are only about 1.4 SDs apart. `nWBV` is clearly different: an **S-shape** around the line (a compressed upper end and a steeper middle).
%[text] The lesson for the t-test: **check normality within each group**, not for the pooled data, and read the *shape* of the deviation off the Q-Q plot.
%[text] 
%[text] ## 4.2 Quantitative tests of normality
%[text] Eyeballing a plot is subjective, so we add formal tests. All of them have the same, *reversed* logic:
%[text] - **H0: the data come from a normal distribution.**
%[text] - A **small** p-value ($\< .05$) is evidence *against* normality.
%[text] - A **large** p-value only means "no evidence against normality". It does *not* prove normality. \
%[text] The Statistics Toolbox has three:
%[text] - `adtest`: **Anderson-Darling**; compares the empirical and the normal cumulative distribution, with extra weight on the *tails*
%[text] - `lillietest`: **Lilliefors** (a Kolmogorov-Smirnov test for the case that mean and SD are estimated from the data)
%[text] - `jbtest`: **Jarque-Bera**; combines skewness and kurtosis (the same idea as the D'Agostino-Pearson test) \
%[text] The popular **Shapiro-Wilk** test is not part of MATLAB (it is available as a File Exchange function, `swtest`; in Python it is `scipy.stats.shapiro`).
groups = {etivF, etivM, T.eTIV, ageF, ageM, T.nWBV};
names  = ["eTIV, women"; "eTIV, men"; "eTIV, pooled"; "Age, women"; "Age, men"; "nWBV, all"];
nTests = numel(groups);
pAD = zeros(nTests, 1);  pLF = zeros(nTests, 1);  pJB = zeros(nTests, 1);
for i = 1:nTests
    [~, pAD(i)] = adtest(groups{i});
    [~, pLF(i)] = lillietest(groups{i});
    [~, pJB(i)] = jbtest(groups{i});
end
normality = table(names, cellfun(@numel, groups(:)), pAD, pLF, pJB, ...
                  VariableNames=["Data", "n", "p_AndersonDarling", "p_Lilliefors", "p_JarqueBera"])
%%
%[text] **Reading the table** ($p \< .05$ means: reject normality). The p-values of these functions are looked up in tables, so they are cut off at the ends (for example 0.001 and 0.5).
%[text] - `eTIV` within each sex: large p-values, no evidence against normality. This agrees with the Q-Q plots.
%[text] - `eTIV` pooled: the p-values drop to about the .05 line (the mixture of the two groups); some tests reject, some do not.
%[text] - `Age`: clearly rejected in both sexes. The age distribution of this sample is far from a bell shape.
%[text] - `nWBV`: strongly rejected, matching the S-shape in the Q-Q plot. \
%[text] 
%[text] ## 4.3 The catch: the tests depend on the sample size
%[text] Formal tests are no replacement for the plot, because their *power* depends on $n$: with huge samples they reject normality for tiny, practically irrelevant deviations. We check this with data that are only *slightly* non-normal: a t distribution with 10 degrees of freedom (almost normal, with slightly heavier tails).
sizes = [10 20 50 100 200 500 1000 2000];
reps = 200;
rejectShare = zeros(size(sizes));
for k = 1:numel(sizes)
    rejections = 0;
    for r = 1:reps
        rejections = rejections + adtest(trnd(10, sizes(k), 1));    % h = 1 if normality is rejected at 5%
    end
    rejectShare(k) = rejections / reps;
end

figure
semilogx(sizes, rejectShare, "o-", "LineWidth", 1.5)
yline(0.05, "k--");
ylim([0 1])
xlabel("Sample size n (log scale)"); ylabel("Share of samples where normality is rejected")
%%
%[text] The dashed line is the 5% we would see for truly normal data. For a distribution that is *almost* normal, the share of rejections climbs as $n$ grows. A rejection with $n = 2000$ does not necessarily mean the t-test is in trouble.
%[text] **Practical rule:** use the plot *and* the test. The Q-Q plot tells you *what kind* of deviation there is and whether it is large; the test tells you whether it is more than chance. For moderate to large groups the t-test is fairly robust against mild non-normality (central limit theorem, last week). With small groups and a clear deviation, use a non-parametric test (we will return to this).
%[text] 
%[text] ## 4.4 Equal variances: Levene's test
%[text] For the independent t-test the group variances should be about equal. In **Levene's test** (here in the median-based version, `"BrownForsythe"`; the function is `vartestn`) H0 is: *the variances are equal* (small p = problem). If the variances are unequal, use the **Welch** test (`"Vartype", "unequal"`).
for col = ["eTIV", "Age"]
    pLev = vartestn(T.(col), T.M_F, "TestType", "BrownForsythe", "Display", "off");
    fprintf("%s: SD men = %.1f, SD women = %.1f, Levene p = %.3f\n", col, std(T.(col)(isM)), std(T.(col)(~isM)), pLev);
end
%%
%[text] Both p-values are large, so the classic and the Welch test give almost the same answer (as in 3.1). Many people simply always use Welch, because it costs almost nothing when the variances happen to be equal.
%[text] 
%[text] ## 5. Statistical power
%[text] **Power** $= 1 - \\beta$ is the probability that the test finds an effect that really exists. It rises with:
%[text] - a larger **effect** (relative to the SD)
%[text] - a larger **sample size**
%[text] - a larger $\\alpha$ (but then more false alarms)
%[text] - a *directed* H1 (if the direction is right) \
%[text] The function `sampsizepwr` computes power or the needed sample size. First a check against our simulation from 1.1 ($d = 0.5$, 30 per group; `[0 1]` = mean and SD of group 1, `0.5` = mean of group 2):
powerFormula = sampsizepwr("t2", [0 1], 0.5, [], 30);
fprintf("power by formula: %.3f | by simulation: %.3f\n", powerFormula, powerRate);
%%
%[text] They agree. Now the practical question: *how many participants per group do we need for 80% power?* This is the **a priori** power analysis, done *before* the study ($\\alpha = .05$).
d = [0.2; 0.5; 0.8];                              % small, medium, large effect
nTwoSided = zeros(3, 1);  nDirected = zeros(3, 1);
for i = 1:3
    nTwoSided(i) = sampsizepwr("t2", [0 1], d(i), 0.8);
    nDirected(i) = sampsizepwr("t2", [0 1], d(i), 0.8, [], "Tail", "right");
end
table(d, nTwoSided, nDirected, VariableNames=["d", "n_per_group_undirected", "n_per_group_directed"])
%%
%[text] The whole power curve, with the non-central t distribution (`nctcdf`): if H1 is true, $t$ is not centered at 0 but at $\\delta = d\\sqrt{n\_1 n\_2/(n\_1+n\_2)}$.
ns = 2:400;                                       % sample sizes per group
figure
hold on
for i = 1:3
    nc = d(i) * sqrt(ns / 2);                     % non-centrality for n1 = n2 = n
    dfs = 2 * ns - 2;
    tcrit = tinv(0.975, dfs);                     % undirected, alpha = .05
    plot(ns, 1 - nctcdf(tcrit, dfs, nc) + nctcdf(-tcrit, dfs, nc), "LineWidth", 1.5)
end
hold off
yline(0.8, "k--");
legend(["small (d = 0.2)", "medium (d = 0.5)", "large (d = 0.8)"], "Location", "southeast", "Box", "off")
xlabel("n per group"); ylabel("Power")
%%
%[text] Small effects need *many* more participants than large ones (about 6 times as many for $d = 0.2$ as for $d = 0.5$, because $n$ grows with $1/d^2$).
%[text] **Power in our data.** For our two examples we use the *observed* effect. (This is *post hoc* power: only a rough guide, because the observed effect is itself uncertain. Proper power analysis happens *before* the study.)
spE = sqrt(((nM - 1) * var(etivM) + (nF - 1) * var(etivF)) / (nM + nF - 2));   % pooled SDs
spA = sqrt(((nM - 1) * var(ageM)  + (nF - 1) * var(ageF))  / (nM + nF - 2));

% "Ratio" = n2/n1 must be >= 1, so n is the size of the SMALLER group (the t-test is symmetric in the two groups)
nSmall = min(nM, nF);   ratio = max(nM, nF) / nSmall;
powerE  = sampsizepwr("t2", [mean(etivF) spE], mean(etivM), [], nSmall, "Ratio", ratio);
powerA  = sampsizepwr("t2", [mean(ageF)  spA], mean(ageM),  [], nSmall, "Ratio", ratio);
needE   = sampsizepwr("t2", [mean(etivF) spE], mean(etivM), 0.8);
needA   = sampsizepwr("t2", [mean(ageF)  spA], mean(ageM),  0.8);

table(["eTIV"; "Age"], [powerE; powerA], [needE; needA], ...
    VariableNames=["Variable", "power_with_real_n", "n_per_group_for_80pct"])
%%
%[text] For `eTIV` (a large effect) very few participants would be enough, and the power is practically 1. For the small age difference the sample is clearly underpowered: a non-significant result must *not* be read as "there is no difference".
%[text] 
%[text] ## 6. Effect sizes
%[text] 
%[text] ## 6.1 Why a p-value is not enough
%[text] The p-value mixes two things: **how big the effect is** and **how large the sample is**. A fixed, tiny effect becomes "significant" if $n$ is large enough. We draw samples of increasing size from a population with a true difference of only $d = 0.1$ (300 repetitions per size, the median is shown):
sizes = [20 50 100 200 500 1000 2000 5000];
medP = zeros(size(sizes));  medD = zeros(size(sizes));
for k = 1:numel(sizes)
    a = randn(sizes(k), 300);
    b = randn(sizes(k), 300) + 0.1;
    [~, p, ~, st] = ttest2(a, b);
    medP(k) = median(p);
    medD(k) = median(st.tstat * sqrt(2 / sizes(k)));      % d = t * sqrt(1/n1 + 1/n2)
end

figure
tiledlayout(1, 2);
nexttile
loglog(sizes, medP, "o-", "LineWidth", 1.5)
yline(0.05, "k--");
xlabel("n per group"); ylabel("Median p-value"); title("p-value: depends strongly on n")
nexttile
semilogx(sizes, medD, "o-", "LineWidth", 1.5)
yline(0.1, "k--");
xlabel("n per group"); ylabel("Median observed d"); title("effect size: settles at the true value 0.1")
%%
%[text] The p-value (left) drops with $n$; the dashed line marks .05. The effect size (right) does not drop; it only becomes more *precise*. So: **always report an effect size next to the p-value.**
%[text] 
%[text] ## 6.2 Cohen's d
%[text] Cohen's $d$ is the difference of the means in units of the pooled standard deviation:
%[text]{"align":"center"} $d = \\frac{\\bar{x}\_1 - \\bar{x}\_2}{s\_{pooled}}$
%[text] Rough benchmarks: **0.2 small, 0.5 medium, 0.8 large** (guides, not laws). The toolbox function is `meanEffectSize` (MATLAB R2023b or newer). It also gives a confidence interval. As a check: $d = t\\sqrt{1/n\_1 + 1/n\_2}$.
dE = meanEffectSize(etivM, etivF, "Effect", "cohen")
dA = meanEffectSize(ageM, ageF, "Effect", "cohen")

[~, ~, ~, stE] = ttest2(etivM, etivF);
fprintf("check with the t value: d(eTIV) = %.3f\n", stE.tstat * sqrt(1 / nM + 1 / nF));
%%
%[text] What does $d$ look like? Two normal curves that are $d$ standard deviations apart:
x = linspace(-4, 6, 400);
figure
tiledlayout(1, 3);
for d0 = [0.2 0.5 0.8]
    nexttile
    area(x, normpdf(x), "FaceAlpha", 0.5)
    hold on
    area(x, normpdf(x, d0), "FaceAlpha", 0.5)
    hold off
    title("d = " + d0); yticks([])
end
%%
%[text] For `eTIV` the sex difference is in the *large* range (the curves overlap little), for `Age` it is *small* (almost complete overlap; the sign is negative because men are a bit younger in this sample). The same data answer two different questions: *is there an effect?* (p-value) and *how big is it?* ($d$).
%[text] 
%[text] ## 6.3 Variance explained: eta squared and omega squared
%[text] Another way to express the effect is as the **share of the variance** explained by group membership. Both can be computed from the t-test:
%[text]{"align":"center"} $\\eta^2 = \\frac{t^2}{t^2 + df} \\qquad\\qquad \\omega^2 = \\frac{t^2 - 1}{t^2 + n\_1 + n\_2 - 1}$
%[text] $\\eta^2$ is biased upwards in small samples; $\\omega^2$ corrects for this. We will meet both again in the ANOVA sessions.
[~, ~, ~, stA] = ttest2(ageM, ageF);
tt = [stE.tstat; stA.tstat];
dff = [stE.df; stA.df];
eta2   = tt.^2 ./ (tt.^2 + dff);
omega2 = (tt.^2 - 1) ./ (tt.^2 + nM + nF - 1);
table(["eTIV"; "Age"], tt, eta2, omega2, VariableNames=["Variable", "t", "eta2", "omega2"])
%%
%[text] For `eTIV` sex explains a substantial share of the variance; for `Age` almost nothing.
%[text] 
%[text] ## 7. Reporting
%[text] A complete report of a t-test contains: the test (and whether Welch), $t$, $df$, the $p$-value, means and SDs of the groups, **and an effect size**. We let MATLAB assemble the sentence, so that no number is copied by hand.
for col = ["eTIV", "Age"]
    xm = T.(col)(isM);  xf = T.(col)(~isM);
    [~, pr, ~, sr] = ttest2(xm, xf, "Vartype", "unequal");
    es = meanEffectSize(xm, xf, "Effect", "cohen");
    if pr < 0.001, pTxt = "p < .001"; else, pTxt = sprintf("p = %.3f", pr); end
    fprintf("%s: men (M = %.1f, SD = %.1f) vs. women (M = %.1f, SD = %.1f), Welch t(%.1f) = %.2f, %s, d = %.2f\n", ...
            col, mean(xm), std(xm), mean(xf), std(xf), sr.df, sr.tstat, pTxt, es.Effect);
end
%%
%[text] **A caution about "significant":**
%[text] - *Statistically* significant only means $p \< \\alpha$. It says nothing about whether the effect is *important* (that is what the effect size is for).
%[text] - *Not significant* does not mean "no effect": it can also mean "too little power".
%[text] - The line at .05 is a convention: $p = .049$ and $p = .051$ are practically the same evidence.
%[text] - If you run many tests, some will be significant by chance. This returns when we compare several groups at once (ANOVA). \
%[text] 
%[text] ## Summary
%[text] - **hypothesis test:** the p-value is the probability of data at least this extreme *if H0 were true*; $\\alpha$ is the false alarm rate we accept, $\\beta$ the miss rate, power $= 1-\\beta$
%[text] - **t-test:** $t$ = difference / standard error, compared with a t distribution with $df = n\_1+n\_2-2$; a directed H1 uses one tail and is fixed *before* the data
%[text] - **three types:** independent (`ttest2`), dependent (`ttest`, a one-sample test on the differences), single group (`ttest` with a constant)
%[text] - **assumptions:** check *within each group*: Q-Q plot first (`qqplot`), then the formal tests (`adtest`, `lillietest`, `jbtest`; H0 = "normal") with their sample-size caveat; Levene (`vartestn`) for equal variances, or simply use Welch
%[text] - **power:** plan the sample size *before* the study (`sampsizepwr`); small effects need many participants
%[text] - **effect size:** always report one next to the p-value (Cohen's $d$ with `meanEffectSize`, $\\eta^2$, $\\omega^2$): the p-value depends on $n$, the effect size does not \
%[text] **Sources**
%[text] - Marcus, D. S. et al. (2007). Open Access Series of Imaging Studies (OASIS): Cross-sectional MRI data in young, middle aged, nondemented, and demented older adults. *Journal of Cognitive Neuroscience, 19*, 1498-1507.
%[text] - Slides: `04_t-TestEffectSizes.pptx` \

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
