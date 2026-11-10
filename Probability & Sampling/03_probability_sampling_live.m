%[text] # Probability and Sampling Theory: applied to the OASIS-1 data
%[text] **Plan for today**
%[text] - **Probability:** relative frequency and the law of large numbers; dependent and independent events, addition and multiplication rule; Bayes' theorem, base rates; binomial, Poisson and normal distribution; z-standardization
%[text] - **Sampling theory:** interpretation of z-values; choosing your sample, standard error, confidence intervals
%[text] - **Toolboxes:** the ready-made probability functions that we use throughout \
%[text] Data: `oasis_cross-sectional.csv` (Marcus et al., 2007). Keep it in the same folder as this script.
%[text] ## 0. The data
%[text] As before, we keep **one row per subject** (the first session, `MR1`): 416 participants.
%[text] For the dementia examples we need the participants who received a **Clinical Dementia Rating (CDR)**. Only 235 of the 416 participants were rated (mostly older ones), so we collect them in a second table, `rated`. We call a participant **demented** if `CDR > 0`.
%[text] **Caution:** OASIS is *not* a random sample of the population. We use it as a "small world" to illustrate the concepts, so probabilities computed here describe *this dataset*, not the real prevalence of dementia.
rng(42);                                           % fixed seed: simulations give the same result every time
raw = readtable("oasis_cross-sectional.csv", "TextType", "string");
T = raw(endsWith(raw.ID, "MR1"), :);              % one row per subject
rated = T(~isnan(T.CDR), :);                      % participants with a dementia rating
fprintf("participants: %d | with a CDR rating: %d\n", height(T), height(rated));
%[text] Moving forward, we will mainly work with a variant of the dataset that solely consists of the MR1 samples. Therefore, it makes sense to save a version that has these rows dropped. This can be done by:
writetable(T, 'oasis_cross-sectional_MR1.csv')
%%
%[text] ## Toolboxes: ready-made probability functions
%[text] In this session we need the normal density, the "norm table" and its inverse, and the binomial and Poisson probabilities. MATLAB has ready-made functions for them. Many such functions live in **toolboxes**: add-on packages that are installed separately and require a license. The probability functions are part of the **Statistics and Machine Learning Toolbox**:
%[text] - `normpdf(x, mu, sigma)`: density of the normal distribution
%[text] - `normcdf(x, mu, sigma)`: the "norm table": the area to the left of `x`, i.e. the probability of a value of `x` or smaller
%[text] - `norminv(p, mu, sigma)`: the inverse of `normcdf`: the value that has the area `p` to its left
%[text] - `binopdf(k, n, p)`: binomial probability of `k` successes in `n` trials
%[text] - `poisspdf(k, lambda)`: Poisson probability of `k` events
%[text] - `zscore(x)`: z-standardization \
%[text] First: do we have the toolbox?
hasStats = license("test", "Statistics_Toolbox") && ~isempty(ver("stats"));
assert(hasStats, "This session needs the Statistics and Machine Learning Toolbox (Home tab, Add-Ons).")
fprintf("Statistics and Machine Learning Toolbox available: %s\n", string(hasStats));
%%
%[text] Two quick examples: the area to the left of z = 1.96, and the z-value that has 97.5% of the area to its left.
normcdf(1.96)
%%
norminv(0.975)
%%
%[text] **Working with toolboxes**
%[text] - Which toolboxes are installed? `ver` lists all installed products.
%[text] - Which toolbox does a function belong to? `doc normcdf` (the product is named at the top of the page), or `which normcdf` (the path shows the toolbox folder).
%[text]     - `help normcdf` also shows the toolbox it belongs to at the end of its output.
%[text] - Which toolboxes does my own script need? `matlab.codetools.requiredFilesAndProducts("scriptname.m")` lists them.
%[text] - Missing a toolbox? Home tab, Add-Ons, Get Add-Ons (this needs a license for the toolbox).
%[text] - Sharing code? Mention the toolboxes it needs. \
%[text] ## 1. Probability
%[text] ## 1.1 What is probability?
%[text] **Inferential statistics** draws conclusions from a *sample* about the underlying *population*. The result is always a **probability**, never a definite answer!
%[text] Probability measures how likely an event is. It lies between 0 and 1 (or 0% and 100%):
%[text] - **1:** the event always happens
%[text] - **0:** the event never happens
%[text] - **0.5:** the event happens as often as it does not happen (chance) \
%[text] Three ways to think about it: an *intuitive* "gut feeling"; the *long-term average* (flip a coin many times, it shows heads about half of the time); the *mathematical* definition (favored outcomes divided by possible outcomes).
%[text] In OASIS: what is the probability that a randomly chosen participant is a woman?
nWomen = sum(T.M_F == "F");
fprintf("p(female) = %d/%d = %.3f\n", nWomen, height(T), nWomen / height(T));
%%
%[text] ## 1.2 Relative frequency
%[text] In the example above we used the **relative frequency** as a measure for probability:
%[text]{"align":"center"} $\\mathrm{relative\\ frequency} = \\frac{\\mathrm{number\\ of\\ times\\ the\\ event\\ occurs}}{\\mathrm{total\\ number\\ of\\ trials}}$
%[text] We can use it as an estimate of the probability **if the event is random and the number of trials is large**. The relative frequency of dementia among the rated participants:
demented = rated.CDR > 0;
fprintf("%d demented out of %d rated participants\n", sum(demented), height(rated));
fprintf("relative frequency of dementia = %.3f\n", mean(demented));
%%
%[text] ## 1.3 Law of large numbers
%[text] For a random event with a fixed probability $p$, the relative frequency will come close to $p$ with an increasing number of trials $N$.
%[text] Five runs of drawing random OASIS participants (our "population" has a share of women of 0.615): the running relative frequency fluctuates strongly at first and then settles down.
N = 2000;
trials = 1:N;
isFemale = T.M_F == "F";
pFemale = mean(isFemale);

figure
hold on
for r = 1:5
    draws = isFemale(randi(numel(isFemale), N, 1));          % random participants, with putting back
    plot(trials, cumsum(draws)' ./ trials, "LineWidth", 1)
end
yline(pFemale, "k:", "p = " + string(round(pFemale, 3)), "LineWidth", 1.5);
hold off
set(gca, "XScale", "log")
ylim([0 1])
xlabel("Number of trials N (log scale)"); ylabel("Relative frequency of women")
%%
%[text] ## 1.4 Dependent vs. independent probability
%[text] **Dependent (conditional) probability:** the probability of $A$ *given* that $B$ is present:
%[text]{"align":"center"} $p(A|B) = \\frac{p(A \\cap B)}{p(B)}$
%[text] **Independent probability:** two events are *stochastically independent* if the occurrence of $A$ is not influenced by the occurrence of $B$.
%[text] In OASIS we define three events among the rated participants:
%[text] - $A$: the participant is demented (`CDR > 0`)
%[text] - $B$: the participant is 70 years or older
%[text] - $F$: the participant is a woman \
A = rated.CDR > 0;
B = rated.Age >= 70;
F = rated.M_F == "F";
p = @(event) mean(event);              % relative frequency of an event (a true/false vector)

fprintf("p(A) = %.3f    p(B) = %.3f    p(A and B) = %.3f\n\n", p(A), p(B), p(A & B));
fprintf("p(A | B) = p(A and B) / p(B) = %.3f\n", p(A & B) / p(B));
fprintf("p(B | A) = p(A and B) / p(A) = %.3f\n", p(A & B) / p(A));
%%
%[text] Note that $p(A|B)$ and $p(B|A)$ are **not the same**: most demented participants are old, but not every old participant is demented.
%[text] Are the events independent? If they were, $p(A \\cap B)$ would equal $p(A) \\cdot p(B)$:
table(["A: demented, B: age >= 70"; "A: demented, F: woman"], [p(A & B); p(A & F)], [p(A) * p(B); p(A) * p(F)], ...
    VariableNames=["Events", "p_X_and_Y", "p_X_times_p_Y"])
%%
fprintf("p(demented | woman) = %.3f\n", p(A(F)));
fprintf("p(demented | man)   = %.3f\n", p(A(~F)));
%[text] In this dataset, dementia and age are strongly dependent; dementia and sex are also dependent (the conditional probabilities differ), although less strongly. These are statements about this sample.
%%
%[text] ## 1.5 Addition and multiplication rule
%[text] **Addition rule:** the probability that $A$ **or** $B$ occurs.
%[text] - disjoint events (never occur together): $p(A \\cup B) = p(A) + p(B)$
%[text] - events that can occur together: $p(A \\cup B) = p(A) + p(B) - p(A \\cap B)$ \
%[text] **Multiplication rule:** the probability that $A$ **and** $B$ occur.
%[text] - independent events: $p(A \\cap B) = p(A) \\cdot p(B)$
%[text] - dependent events: $p(A \\cap B) = p(A|B) \\cdot p(B) = p(B|A) \\cdot p(A)$ \
%[text] We check the rules on our data. In each row, the left and right side must agree:
cdr0  = rated.CDR == 0;            % disjoint: nobody has both ratings
cdr05 = rated.CDR == 0.5;

rules = ["addition, disjoint: p(CDR 0 or CDR 0.5)"; "addition, not disjoint: p(A or B)"; ...
         "multiplication, dependent: p(A|B) * p(B)"; "multiplication, dependent: p(B|A) * p(A)"];
leftSide  = [p(cdr0 | cdr05); p(A | B); p(A & B); p(A & B)];
rightSide = [p(cdr0) + p(cdr05); p(A) + p(B) - p(A & B); p(A(B)) * p(B); p(B(A)) * p(A)];
table(rules, leftSide, rightSide)
%%
%[text] ## 1.6 Bayesian probability
%[text] Bayes' theorem relates the two dependent probabilities $p(A|B)$ and $p(B|A)$:
%[text]{"align":"center"} $p(A|B) = \\frac{p(A) \\cdot p(B|A)}{p(B)}$
%[text] **Example: Covid test.** Sensitivity (positive test if infected) 99%, false alarms (positive test if not infected) 5%, probability of having Covid 0.1%. How likely is it that we have Covid if the test is positive?
%[text] To compute $p(\\mathrm{pos.})$ we use both rules: a positive test is *either* (infected **and** positive) *or* (not infected **and** positive):
%[text]{"align":"center"} $p(C|\\mathrm{pos.}) = \\frac{p(C) \\cdot p(\\mathrm{pos.}|C)}{p(\\mathrm{pos.}|C)\\,p(C) + p(\\mathrm{pos.}|\\sim C)\\,p(\\sim C)}$
posterior = @(prior, sens, falseAlarm) sens .* prior ./ (sens .* prior + falseAlarm .* (1 - prior));

prior = 0.001; sensitivity = 0.99; falseAlarm = 0.05;
pPos = sensitivity * prior + falseAlarm * (1 - prior);
fprintf("p(positive test)    = 0.99 * 0.001 + 0.05 * 0.999 = %.4f\n", pPos);
fprintf("p(Covid | positive) = 0.99 * 0.001 / %.4f = %.3f\n", pPos, posterior(prior, sensitivity, falseAlarm));
%%
%[text] Even after a positive test, the probability is only about 1.9%: the disease is so rare that most positive tests are false alarms.
%[text] **Bayesian updating:** use the calculated probability (the *posterior*) as the *prior* in the next calculation. A second positive test (assuming the tests are independent, as on the slide). The slide rounds the first posterior to 0.019 and gets 27.7%; carrying the unrounded value through gives slightly more (28.2%).
fprintf("second positive test, prior 0.019: p(Covid) = %.3f\n\n", posterior(0.019, 0.99, 0.05));

belief = 0.001;
for test = 1:3
    belief = posterior(belief, 0.99, 0.05);
    fprintf("after positive test %d: p(Covid) = %.3f\n", test, belief);
end
%%
%[text] ## OASIS: a screening test for dementia
%[text] The same logic applies to a screening test. We use the `MMSE` score as a "test" for dementia ($A$): a participant tests **positive** if `MMSE` `<= 26`. From the data we estimate:
%[text] - **sensitivity:** $p(\\mathrm{positive} | \\mathrm{demented})$
%[text] - **false alarm rate:** $p(\\mathrm{positive} | \\mathrm{not\\ demented})$
%[text] - **prior (base rate):** $p(\\mathrm{demented})$ \
%[text] Bayes' theorem should reproduce what we get by simply counting, $p(\\mathrm{demented}|\\mathrm{positive})$:
tested = rated(~isnan(rated.MMSE), :);
dem = tested.CDR > 0;
pos = tested.MMSE <= 26;

sensitivity = mean(pos(dem));
falseAlarm  = mean(pos(~dem));
baseRate    = mean(dem);

fprintf("n = %d\n", height(tested));
fprintf("sensitivity           p(pos | demented)     = %.3f\n", sensitivity);
fprintf("false alarm rate      p(pos | not demented) = %.3f\n", falseAlarm);
fprintf("base rate             p(demented)           = %.3f\n\n", baseRate);
fprintf("p(demented | pos), counting:       %.3f\n", mean(dem(pos)));
fprintf("p(demented | pos), Bayes' theorem: %.3f\n", posterior(baseRate, sensitivity, falseAlarm));
%%
%[text] Both ways agree. But in OASIS, dementia is very common (about 43% of the rated participants). In a population where it is rarer, the **same test** is much less informative:
rates = [baseRate; 0.10; 0.05; 0.01];
table(["OASIS"; "10%"; "5%"; "1%"], rates, posterior(rates, sensitivity, falseAlarm), ...
    VariableNames=["Population", "base_rate", "p_demented_given_positive"])
%%
%[text] Depending on where we split, the same data give "176% more" or "25% more": the relative increase changes dramatically with the base rate, while the difference in percentage points shows the absolute gap directly. Reporting **both the base rate and the difference in percentage points** avoids misunderstandings.
%[text] ## 1.7 Probability distributions
%[text] A **probability distribution** tells us how likely every potential value of a variable is.
%[text] - **discrete** distributions are for discrete / categorical variables (or for categories within a continuous distribution, i.e. a histogram): there is a probability for each value
%[text] - **continuous** distributions are for continuous variables: there are only probabilities for *ranges* of values, and the probability is the **area under the curve** \
%[text] In OASIS, the dementia rating `CDR` is a **discrete** variable with four values. Each has a probability, and all probabilities add up to 1.
[counts, levels] = groupcounts(rated.CDR);
cdrP = counts / sum(counts);

figure
b = bar(categorical(string(levels), string(levels)), cdrP);
text(b.XEndPoints, b.YEndPoints, string(round(cdrP, 3)), "HorizontalAlignment", "center", "VerticalAlignment", "bottom")
xlabel("Clinical Dementia Rating (CDR)"); ylabel("Probability")
fprintf("sum of all probabilities: %g\n", sum(cdrP));
%%
%[text] The estimated total intracranial volume (`eTIV`) is a **continuous** variable. If we sort it into bins of width 100 mm^3, the histogram is a *discrete* distribution (left: one probability per bin, bars add up to 1). For the *continuous* distribution (right), we scale the histogram so that the **total area is 1** (a density) and compare it with a normal curve with the same mean and SD. The probability of a range, here 1400 to 1600 mm^3, is the area under the curve in that range.
x = T.eTIV;
mu = mean(x); s = std(x);
edges = 1100:100:2100;
xg = linspace(1100, 2100, 400);
lo = 1400; hi = 1600;

figure
tiledlayout(1, 2);

nexttile
histogram(x, edges, "Normalization", "probability", "FaceColor", [0.8 0.8 0.8], "EdgeColor", "w")
xlabel("eTIV (mm^3)"); ylabel("Probability of the bin")

nexttile
histogram(x, edges, "Normalization", "pdf", "FaceColor", [0.8 0.8 0.8], "EdgeColor", "w")
hold on
plot(xg, normpdf(xg, mu, s), "Color", [0 0.45 0.74], "LineWidth", 2)
mask = xg >= lo & xg <= hi;
hArea = area(xg(mask), normpdf(xg(mask), mu, s), "FaceColor", [0 0.45 0.74], "FaceAlpha", 0.4, "EdgeColor", "none");
hold off
legend(hArea, "area between " + lo + " and " + hi, "Box", "off", "Location", "northeast")
xlabel("eTIV (mm^3)"); ylabel("Density")
%%
fprintf("p(%d <= eTIV <= %d): counting participants       = %.3f\n", lo, hi, mean(x >= lo & x <= hi));
fprintf("p(%d <= eTIV <= %d): area under the normal curve = %.3f\n", lo, hi, normcdf(hi, mu, s) - normcdf(lo, mu, s));
%%
%[text] ## 1.8 Binomial distribution
%[text] The probability of $k$ successes in $n$ trials, with a base probability $p$ for a success. It is for **discrete** variables with a **fixed number of trials**.
%[text]{"align":"center"} $p(k|n,p) = \\binom{n}{k}\\, p^k (1-p)^{n-k} \\qquad\\qquad \\binom{n}{k} = \\frac{n!}{k!\\,(n-k)!}$
%[text] In OASIS, we draw **10 random participants** with replacement (putting back) and count the women among them. With $p = 0.615$ the number of women should follow a binomial distribution. We repeat the experiment 20,000 times and compare the relative frequencies with the binomial probabilities.
n = 10;
nExperiments = 20000;
women = sum(isFemale(randi(numel(isFemale), nExperiments, n)), 2);

k = 0:n;
observed = histcounts(women, -0.5:1:n + 0.5, "Normalization", "probability");
expected = binopdf(k, n, pFemale);

figure
bar(k, observed, "FaceColor", [0.8 0.8 0.8], "EdgeColor", "k")
hold on
plot(k, expected, "o", "Color", [0.85 0.2 0.2], "MarkerFaceColor", [0.85 0.2 0.2])
hold off
xticks(k); ylim([0 0.33])
xlabel("Number of women among 10 participants"); ylabel("Probability")
legend(["simulated experiments", "binomial (n = 10, p = " + string(round(pFemale, 3)) + ")"], "Location", "northwest", "Box", "off")
fprintf("mean number of women: simulated %.2f, n * p = %.2f\n", mean(women), n * pFemale);
%%
%[text] ## 1.9 Poisson distribution
%[text] The probability of $k$ events if the *average* number of events in an interval is $\\lambda$. It is for **discrete** variables in a **fixed interval**.
%[text]{"align":"center"} $p(k|\\lambda) = \\frac{\\exp(-\\lambda)\\,\\lambda^k}{k!}$
%[text] **Example from the slides:** I get four emails a day ($\\lambda = 4$). How likely are different numbers of emails tomorrow?
lambda = 4;
k = 0:15;
poissonProb = poisspdf(k, lambda);

figure
bar(k, poissonProb, "EdgeColor", "k")
xlabel("Number of emails k"); ylabel("Probability")
fprintf("p(no email at all) = %.3f\n", poissonProb(1));
fprintf("p(8 or more)       = %.3f\n", 1 - sum(poissonProb(1:8)));
%%
%[text] ## 1.10 Normal distribution
%[text] The normal distribution is for **continuous variables** whose values spread **symmetrically** around the mean.
%[text] - it usually results if a variable is influenced by many different, random, independent factors
%[text] - there are infinitely many normal distributions: they all have the same bell shape and differ only in **mean** and **standard deviation**. Mean and SD are all we need to describe the population.
%[text] - a normal distribution with $\\mu = 0$ and $\\sigma = 1$ is the **standard normal distribution** \
%[text] All parametric tests we will discuss (t-test, ANOVA) **assume normally distributed data**.
z = linspace(-3, 3, 400);

figure
plot(z, normpdf(z, 0, 1), "k", "LineWidth", 2)
xline(-1, "--", "-1 SD", "Color", [0.5 0.5 0.5]);
xline(0, "--", "mean", "Color", [0.5 0.5 0.5]);
xline(1, "--", "+1 SD", "Color", [0.5 0.5 0.5]);
title("Standard normal distribution")
xlabel("z"); ylabel("Probability density")
%%
%[text] **Do our data look normal?** Histograms of four OASIS columns, each with the normal curve that has the same mean and SD:
cols = ["eTIV", "nWBV", "Age", "MMSE"];
colLabels = ["eTIV (mm^3)", "Normalized whole-brain volume", "Age (years)", "MMSE score"];

figure
tiledlayout(2, 2);
for i = 1:4
    x = rmmissing(T.(cols(i)));
    nexttile
    histogram(x, 20, "Normalization", "pdf", "FaceColor", [0.8 0.8 0.8], "EdgeColor", "w")
    hold on
    xg = linspace(min(x), max(x), 300);
    plot(xg, normpdf(xg, mean(x), std(x)), "Color", [0 0.45 0.74], "LineWidth", 2)
    hold off
    xlabel(colLabels(i)); ylabel("Density")
end
%%
%[text] For a normal distribution, 68.3% of the values lie within +-1 SD of the mean and 95.4% within +-2 SD. How close are our columns?
within1 = zeros(5, 1);
within2 = zeros(5, 1);
for i = 1:4
    x = rmmissing(T.(cols(i)));
    within1(i) = mean(abs(x - mean(x)) < std(x));
    within2(i) = mean(abs(x - mean(x)) < 2 * std(x));
end
within1(5) = normcdf(1, 0, 1) - normcdf(-1, 0, 1);
within2(5) = normcdf(2, 0, 1) - normcdf(-2, 0, 1);
table([cols'; "normal distribution"], within1, within2, VariableNames=["Column", "Within_1_SD", "Within_2_SD"])
%%
%[text] `eTIV` is close to normal. `nWBV` is somewhat left-skewed, `MMSE` has a ceiling effect, and `Age` consists of two clusters: these are the "paranormal distributions" for which a normal-based calculation can be misleading.
%[text] ## Checking normality with a Q-Q plot
%[text] A histogram with a normal curve on top depends on the number of bins and on our eye. A **Q-Q plot** (quantile-quantile plot) is a sharper tool. It compares every observed value with the value we would **expect if the data were normally distributed**:
%[text] 1. sort the data
%[text] 2. for each value, compute the share of the data at or below it (using its rank)
%[text] 3. look up which z-value belongs to this share in the standard normal distribution (the inverse norm table, `norminv`)
%[text] 4. plot the expected z-value (x-axis) against the observed value (y-axis) \
%[text] If the data are normal, **the points fall on a straight line**. We draw the line that a perfectly normal variable with the same mean and SD would follow. For `eTIV`, step by step:
x = T.eTIV;
n = numel(x);

observed = sort(x);                         % 1. sort the data
prob = ((1:n)' - 0.5) / n;                  % 2. share of the data up to each rank
expectedZ = norminv(prob, 0, 1);            % 3. z-value a normal distribution has at that share

table(observed(1:4), prob(1:4), expectedZ(1:4), VariableNames=["Observed_eTIV", "Share", "Expected_z"])
%%
figure
scatter(expectedZ, observed, 10, "filled", "MarkerFaceAlpha", 0.7)                    % 4. plot
hold on
hLine = plot(expectedZ, mean(x) + std(x) * expectedZ, "k", "LineWidth", 1.5);
hold off
legend(hLine, "perfectly normal (same mean and SD)", "Box", "off", "Location", "northwest")
xlabel("Expected z-value if normal"); ylabel("Observed eTIV (mm^3)")
%%
%[text] The points follow the line closely: `eTIV` is close to normal. The same for all four columns:
figure
tiledlayout(2, 2);
for i = 1:4
    x = rmmissing(T.(cols(i)));
    n = numel(x);
    expectedZ = norminv(((1:n)' - 0.5) / n, 0, 1);
    nexttile
    scatter(expectedZ, sort(x), 8, "filled", "MarkerFaceAlpha", 0.7)
    hold on
    plot(expectedZ, mean(x) + std(x) * expectedZ, "k", "LineWidth", 1.5)
    hold off
    xlabel("Expected z-value if normal"); ylabel(colLabels(i))
end
%%
%[text] How to read the plots:
%[text] - `eTIV`: the points stay close to the line. Close to normal.
%[text] - `nWBV`: an S-shape. The highest values lie far *below* the line: the data stop at about 0.9, while a normal distribution with this mean and SD would produce larger values.
%[text] - `Age`: a strong S-shape, steep in the middle and with long flat stretches at both ends (the two clusters). A normal distribution would even predict negative ages.
%[text] - `MMSE`: a staircase (whole-number scores) with a plateau at the top (the ceiling effect) and low scores far below the line. \
%[text] In general: both ends bending away to the same side (a banana shape) means a skewed distribution; an S-shape means lighter tails than normal; a reversed S means heavier tails; steps and plateaus mean many identical values.
%[text] Even truly normal data never form a perfect line. To calibrate our eye, four Q-Q plots of samples that *are* normal, each with 50 values:
stream = RandStream("mt19937ar", "Seed", 1);    % separate random stream: does not change the numbers used elsewhere

figure
tiledlayout(1, 4);
for i = 1:4
    x = randn(stream, 50, 1);
    expectedZ = norminv(((1:50)' - 0.5) / 50, 0, 1);
    nexttile
    scatter(expectedZ, sort(x), 8, "filled", "MarkerFaceAlpha", 0.7)
    hold on
    plot(expectedZ, mean(x) + std(x) * expectedZ, "k", "LineWidth", 1.5)
    hold off
    xlabel("Expected z-value if normal"); ylabel("Observed value")
end
%[text] Some wiggle, especially at the ends, is normal. The deviations in |nWBV|, |Age| and |MMSE| are far larger and *systematic* (a clear curve, a plateau, a gap).
%%
%[text] ## 1.11 z-standardization
%[text] We can transform every normal distribution into a standard normal distribution:
%[text]{"align":"center"} $x\_{new} = z(x) = \\frac{x\_{old} - \\mu}{\\sigma}$
%[text] The result tells us how many standard deviations a value is above (positive) or below (negative) the mean. Standardized values are easy to interpret, because their probabilities can be found in norm tables.
%[text] We z-standardize `eTIV` with its sample mean and standard deviation. The mean becomes 0 and the SD becomes 1, but the **shape of the distribution does not change**.
zEtiv = (T.eTIV - mean(T.eTIV)) / std(T.eTIV);
fprintf("z(eTIV): mean = %.3f, SD = %.3f\n", mean(zEtiv), std(zEtiv));
fprintf("same as the toolbox function zscore: %s\n", string(all(abs(zEtiv - zscore(T.eTIV)) < 1e-10)));

figure
tiledlayout(1, 2);
nexttile
histogram(T.eTIV, 20, "FaceColor", [0.8 0.8 0.8], "EdgeColor", "w")
xlabel("eTIV (mm^3)"); ylabel("Number of participants")
nexttile
histogram(zEtiv, 20, "FaceColor", [0.8 0.8 0.8], "EdgeColor", "w")
xlabel("z(eTIV)"); ylabel("Number of participants")
%%
%[text] ## 2. Sampling Theory
%[text] ## 2.1 Interpretation of sampled z-values
%[text] The probability of a value between $x\_{min}$ and $x\_{max}$ is the **area under the curve** between those two values. Norm tables for the z-distribution give the probability for **z or smaller**, i.e. the area to the *left* of each value. The function `normcdf` is such a norm table.
%[text] In OASIS, we use z-values to compute probabilities for `eTIV` and `nWBV`, and compare them with the actual relative frequencies:
specs = {"eTIV", 1300, 1600; "nWBV", 0.70, 0.85};
variable = strings(4, 1); question = strings(4, 1);
normalCurve = zeros(4, 1); dataShare = zeros(4, 1);
r = 0;
for i = 1:size(specs, 1)
    col = specs{i, 1}; lo = specs{i, 2}; hi = specs{i, 3};
    x = T.(col);
    zLo = (lo - mean(x)) / std(x);
    zHi = (hi - mean(x)) / std(x);

    r = r + 1;
    variable(r) = col;
    question(r) = "p(x <= " + string(lo) + ")";
    normalCurve(r) = normcdf(zLo, 0, 1);
    dataShare(r) = mean(x <= lo);

    r = r + 1;
    variable(r) = col;
    question(r) = "p(" + string(lo) + " <= x <= " + string(hi) + ")";
    normalCurve(r) = normcdf(zHi, 0, 1) - normcdf(zLo, 0, 1);
    dataShare(r) = mean(x >= lo & x <= hi);
end
table(variable, question, normalCurve, dataShare)
%%
%[text] For the nearly normal `eTIV` the normal curve gives a good estimate. For the left-skewed `nWBV` it is noticeably off, especially in the lower tail (10% of the participants have `nWBV` of 0.70 or less, the normal curve says 7%), which is why we should check the distribution before we rely on z-values.
%[text] **A word on "significant":** this word has a meaning in statistics. Use it only for *statistical* significance, never as a synonym for "large".
%[text] ## 2.2 Choosing your sample
%[text] To draw conclusions about the underlying population, the sample needs to be **representative**. Drawing from the population **randomly** ensures this best. Many things can be sampled randomly: participants, neurons, trials, ...
%[text] The **standard error of the mean** (SEM) quantifies how well our sample mean represents the population mean:
%[text]{"align":"center"} $SEM = \\frac{s}{\\sqrt{N}}$
%[text] With the SEM we can give a **confidence interval** in which the "true" population mean lies with a given probability. The z-distribution tells us which value belongs to which probability: for a 95% interval, 2.5% of the area must lie to the left and 2.5% to the right, so we need $z = 1.96$:
confLevels = [0.80; 0.90; 0.95; 0.99];
table(["80%"; "90%"; "95%"; "99%"], norminv(1 - (1 - confLevels) / 2, 0, 1), VariableNames=["ConfidenceLevel", "z"])
z = linspace(-3, 3, 400);

figure
hold on
plot(z, normpdf(z, 0, 1), "k", "LineWidth", 2)
area(z(z<-1.96), normpdf(z(z<-1.96), 0, 1), "FaceColor", [1, 0, 0])
area(z(z>1.96), normpdf(z(z>1.96), 0, 1), "FaceColor", [1, 0, 0])
xline(-1.96, "--", "-1.96", "Color", [0.5 0.5 0.5]);
xline(0, "--", "mean", "Color", [0.5 0.5 0.5]);
xline(1.96, "--", "1.96", "Color", [0.5 0.5 0.5]);
title("Standard normal distribution")
xlabel("z"); ylabel("Probability density")
%%
%[text]{"align":"center"} $\\mathrm{95\\%\\ CI} = \\bar{x} \\pm 1.96 \\cdot SEM$
%[text] (For small samples the t-distribution is used instead of z. This is a topic of the next session.)
%[text] **Experiment:** we pretend that the 416 participants are our *population*, so we know the "true" mean of `nWBV`. We draw a random sample of 30 participants and compute the confidence interval.
nwbv = T.nWBV;
trueMean = mean(nwbv);
z95 = norminv(0.975, 0, 1);

sample = nwbv(randperm(numel(nwbv), 30));
m = mean(sample);
sem = std(sample) / sqrt(numel(sample));
ci = [m - z95 * sem, m + z95 * sem];

fprintf("'true' population mean: %.4f\n", trueMean);
fprintf("sample mean = %.4f, SEM = %.4f\n", m, sem);
fprintf("95%% CI: [%.4f, %.4f] -> contains the true mean: %s\n", ci(1), ci(2), string(ci(1) <= trueMean && trueMean <= ci(2)));
%%
%[text] A single interval can miss the true mean. 95% means: if we repeat the whole procedure many times, about 95% of the intervals contain the true mean. Here are 50 random samples:
nDraws = 50;
n = 30;
means = zeros(nDraws, 1);
sems = zeros(nDraws, 1);
for i = 1:nDraws
    s = nwbv(randperm(numel(nwbv), n));
    means(i) = mean(s);
    sems(i) = std(s) / sqrt(n);
end
hit = means - z95 * sems <= trueMean & trueMean <= means + z95 * sems;

figure
hold on
for i = 1:nDraws
    if hit(i)
        c = [0 0.45 0.74];
    else
        c = [0.8 0.15 0.15];
    end
    plot([means(i) - z95 * sems(i), means(i) + z95 * sems(i)], [i i], "Color", c, "LineWidth", 2)
    plot(means(i), i, "ko", "MarkerSize", 3, "MarkerFaceColor", "k")
end
xline(trueMean, "k:", "true mean", "LineWidth", 1.5);
hold off
xlabel("nWBV: sample mean with 95% confidence interval"); ylabel("Sample")
fprintf("%d of %d intervals contain the true mean (red = missed it)\n", sum(hit), nDraws);
%%
%[text] With many more samples, the share of intervals that contain the true mean should be close to 95%:
nDraws = 10000;
means = zeros(nDraws, 1);
sems = zeros(nDraws, 1);
for i = 1:nDraws
    s = nwbv(randperm(numel(nwbv), n));
    means(i) = mean(s);
    sems(i) = std(s) / sqrt(n);
end
coverage = mean(means - z95 * sems <= trueMean & trueMean <= means + z95 * sems);
fprintf("share of 95%% intervals containing the true mean: %.3f\n", coverage);
%%
%[text] ## A sample that is not representative
%[text] What if the sample is **not random**? Suppose we only recruit participants younger than 30 (138 of the 416). Their brains are, on average, larger than those of the whole group, and the sample means no longer scatter around the true mean:
young = T.nWBV(T.Age < 30);
meansYoung = zeros(nDraws, 1);
semsYoung = zeros(nDraws, 1);
for i = 1:nDraws
    s = young(randperm(numel(young), n));
    meansYoung(i) = mean(s);
    semsYoung(i) = std(s) / sqrt(n);
end
coverageYoung = mean(meansYoung - z95 * semsYoung <= trueMean & trueMean <= meansYoung + z95 * semsYoung);

figure
histogram(means, 40, "FaceAlpha", 0.6)
hold on
histogram(meansYoung, 40, "FaceAlpha", 0.6)
xline(trueMean, "k:", "true mean", "LineWidth", 1.5);
hold off
legend(["random samples", "only participants < 30"], "Location", "northwest", "Box", "off")
xlabel("Mean nWBV of " + n + " participants"); ylabel("Number of samples")

fprintf("random samples:       95%% intervals contain the true mean in %.1f%% of the cases\n", 100 * coverage);
fprintf("samples of the young: 95%% intervals contain the true mean in %.1f%% of the cases\n", 100 * coverageYoung);
%%
%[text] The standard error only describes the *random* variation between samples. It cannot repair a sample that is systematically different from the population. Hence: **sample randomly**.
%[text] ## Summary
%[text] - **probability:** between 0 and 1; estimated by the relative frequency (law of large numbers)
%[text] - **conditional probability:** $p(A|B) = p(A \\cap B) / p(B)$; not the same as $p(B|A)$
%[text] - **addition / multiplication rule:** "or" adds (minus the overlap), "and" multiplies (with the conditional probability if dependent)
%[text] - **Bayes' theorem:** links $p(A|B)$ and $p(B|A)$; the base rate matters
%[text] - **percentage increases:** always name the base rate, prefer percentage points
%[text] - **binomial distribution:** $k$ successes in a fixed number of trials $n$
%[text] - **Poisson distribution:** $k$ events in a fixed interval, mean = variance = $\\lambda$
%[text] - **normal distribution:** symmetric bell shape; described by mean and SD; assumed by parametric tests; check it (histogram, Q-Q plot)
%[text] - **z-standardization:** $z = (x - \\mu)/\\sigma$, norm tables give the area to the left
%[text] - **sampling:** sample randomly; SEM and confidence interval quantify how well the sample mean represents the population mean
%[text] - **toolboxes:** ready-made functions (`normpdf`, `normcdf`, `norminv`, `binopdf`, `poisspdf`, `zscore`); check what you have, and know what your code needs \
%[text] **Source**
%[text] - Marcus, D. S. et al. (2007). Open Access Series of Imaging Studies (OASIS): Cross-sectional MRI data in young, middle aged, nondemented, and demented older adults. *Journal of Cognitive Neuroscience, 19*, 1498-1507. \

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
