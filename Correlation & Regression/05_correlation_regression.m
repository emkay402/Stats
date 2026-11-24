%[text] # Correlation and Regression: applied to the OASIS-1 data
%[text] 
%[text] - **0. Data** (3 min)
%[text] - **1. Correlation:** covariance, Pearson's $r$, $r^2$, assumptions, testing and comparing correlations (28 min)
%[text] - **2. Linear regression:** least squares, interpretation, explained variance, standard errors, assumptions (30 min)
%[text] - **3. A subgroup:** the same analysis for the participants with a CDR rating (8 min)
%[text] - **4. Summary** (1 min) \
%[text] Data: `oasis_cross-sectional_MR1.csv` (Marcus et al., 2007), the first session of every subject. Keep it in the same folder as this script. The two variables that run through the session are `Age` (years) and `nWBV` (normalized whole-brain volume: the share of the intracranial volume that is brain tissue).
%[text] 
%[text] ## 0. The data
rng(42)                                           % fixed seed
T = readtable("oasis_cross-sectional_MR1.csv", "TextType", "string");
assert(height(T) == 416, "Expected 416 participants (one row per subject).")

age  = T.Age;                                     % years
nwbv = T.nWBV;                                    % normalized whole-brain volume
etiv = T.eTIV;                                    % head size
n = height(T);
summary(T(:, ["Age", "nWBV", "eTIV"]))
%[text] 
%[text] ## 1. Correlation
%[text] 
%[text] ## 1.1 What is a correlation?
%[text] A correlation measures the strength and direction of the **linear relationship between two variables**:
%[text] - **positive:** high values in one variable go along with high values in the other
%[text] - **negative:** high values in one variable go along with low values in the other
%[text] - **none:** knowing one variable tells us nothing (linear) about the other \
%[text] The standard picture is the **scatter plot**: one dot per person.
figure
tiledlayout(1, 2);
nexttile
scatter(age, nwbv, 12, "filled", "MarkerFaceAlpha", 0.6)
xlabel("Age (years)"); ylabel("nWBV"); title("strong negative relationship")
nexttile
scatter(etiv, nwbv, 12, "filled", "MarkerFaceAlpha", 0.6)
xlabel("eTIV (mm^3)"); ylabel("nWBV"); title("no relationship")
%%
%[text] Left: the older the participant, the lower the brain volume. Right: head size says nothing about the *normalized* brain volume (`nWBV` is already divided by the head size, so this is what we expect).
%[text] ## 1.2 Covariance
%[text] The **covariance** measures how two variables vary *together*: for each person we multiply the deviation of x from its mean with the deviation of y from its mean, and average the products (dividing by $N-1$, like the variance):
%[text]{"align":"center"} $cov\_{xy} = \\frac{\\sum\_i (x\_i - \\bar{x})(y\_i - \\bar{y})}{N - 1}$
%[text] Above average in both variables (or below in both): the product is positive. Above in one and below in the other: negative.
dx = age - mean(age);                             % deviation of every age from the mean age
dy = nwbv - mean(nwbv);
products = dx .* dy;                              % one product per person

covHand = sum(products) / (n - 1);
C = cov(age, nwbv);                               % 2x2 matrix: variances on the diagonal, covariance off the diagonal
fprintf("covariance by hand: %.4f | cov: %.4f\n", covHand, C(1, 2));
fprintf("share of persons with a positive product: %.2f\n", mean(products > 0));
%%
%[text] The covariance is negative, and for about nine out of ten persons the two deviations point in *opposite* directions. But **how strong** is the relationship? The number depends on the units: it is measured in "years x nWBV units".
Cmonths = cov(age * 12, nwbv);                    % the same data, age in months
fprintf("covariance with age in years : %.3f\n", C(1, 2));
fprintf("covariance with age in months: %.3f   (x12, same relationship)\n", Cmonths(1, 2));
%[text] 
%[text] ## 1.3 Pearson's correlation coefficient
%[text] Pearson's **r** divides the covariance by the **product of the two standard deviations**, which removes the units:
%[text]{"align":"center"} $r\_{xy} = \\frac{cov\_{xy}}{s\_x \\cdot s\_y}$
%[text] Equivalently: *the correlation is the covariance of the z-standardized values* (`zscore`). It lies between **-1** (perfect negative linear relationship) and **+1** (perfect positive); around 0 means no linear relationship.
sx = std(age);  sy = std(nwbv);
rHand = covHand / (sx * sy);

Cz = cov(zscore(age), zscore(nwbv));              % covariance of the z-scores
[rCorr, pCorr] = corr(age, nwbv);                 % the toolbox function (r and the p-value)

fprintf("r = cov / (sx * sy)     : %.4f\n", rHand);
fprintf("r = cov of the z-scores : %.4f\n", Cz(1, 2));
fprintf("corr                    : %.4f\n", rCorr);
fprintf("r with age in months    : %.4f   (unchanged)\n", corr(age * 12, nwbv));
fprintf("r(eTIV, nWBV) = %.3f   (the 'no relationship' plot)\n", corr(etiv, nwbv));
%%
%[text] Three routes, one number: **r = -0.87**, a strong negative correlation. Changing the unit (years to months) does not change r. **Rules of thumb:** $|r|$ around .1 is small, around .3 medium, above .5 large. Always look at the scatter plot too.
%[text] ## 1.4 The coefficient of determination, r^2
%[text] Squaring the correlation gives **r^2**: the **share of the variance that two variables have in common** (the "shared" variance). It ranges from 0 to 1. In words: *how much of the variance of one variable is explained by the other?* The relationship is symmetric.
r2 = rCorr^2;
fprintf("r = %.3f  ->  r^2 = %.3f\n", rCorr, r2);
fprintf("%.0f%% of the variance of nWBV is shared with Age; %.0f%% is not.\n", 100 * r2, 100 * (1 - r2));
%[text] 
%[text] ## 1.5 When can I use a correlation?
%[text] 1. **equal-interval scale** (and approximately normal data; strictly a bivariate normal distribution, which matters for the test in 1.6)
%[text] 2. **only linear relationships:** r measures how well the points follow a *straight line*
%[text] 3. **homoscedasticity:** the spread of y should be about the same at every value of x \
%[text] An instructive case is the **MMSE** (cognitive screening score, 0 to 30) against `Age`. It is only available for the participants with a clinical rating (n = 235).
hasMMSE = ~isnan(T.MMSE);
ageMM = age(hasMMSE);
mmse  = T.MMSE(hasMMSE);

pMM = polyfit(ageMM, mmse, 1);                    % straight line: [slope intercept]
resMM = mmse - polyval(pMM, ageMM);               % distance from the line

figure
tiledlayout(1, 2);
nexttile
scatter(ageMM + 0.6 * (rand(size(ageMM)) - 0.5), mmse + 0.4 * (rand(size(mmse)) - 0.5), 12, "filled", "MarkerFaceAlpha", 0.6)
hold on
xl = [min(ageMM) max(ageMM)];
plot(xl, polyval(pMM, xl), "k", "LineWidth", 1.5)
hold off
xlabel("Age (years)"); ylabel("MMSE"); title("MMSE against Age (jittered)")
nexttile
scatter(ageMM, resMM, 12, "filled", "MarkerFaceAlpha", 0.6)
yline(0, "k");
xlabel("Age (years)"); ylabel("distance from the line"); title("spread around the line")

bin = discretize(ageMM, [17 60 70 80 100], "categorical", ["<60", "60-69", "70-79", "80+"]);
spread = groupsummary(table(bin, resMM), "bin", "std", "resMM")
fprintf("Pearson r = %.3f | Spearman rho = %.3f\n", corr(ageMM, mmse), corr(ageMM, mmse, "Type", "Spearman"));
%%
%[text] Two problems are visible:
%[text] - **Ceiling effect:** most participants score 29 or 30, so the points are squeezed against the upper limit. The MMSE is also not a true equal-interval scale.
%[text] - **Unequal spread (heteroscedasticity):** below age 60 nearly everybody scores close to the maximum, above 60 some scores fall far below. The spread around the line is about four to five times larger in the older groups. A single r (here -.25) averages over very different situations. \
%[text] When the scale is only ordinal, or the relationship is monotonic but not linear, the **Spearman rank correlation** is an alternative: Pearson's r computed on the *ranks* (here -.34, because it is less bothered by the ceiling).
%[text] ## 1.6 Testing a correlation, and comparing two correlations
%[text] **Is a correlation different from zero?** A t-test with $df = N - 2$ (H0: the correlation in the population is 0):
%[text]{"align":"center"} $t = \\frac{r\\sqrt{N-2}}{\\sqrt{1-r^2}}$
%[text] Correlations are *not* on an equal-interval scale (their distribution is skewed near +-1), so the confidence interval is built on **Fisher's z-transformation** (not the same as the z-standardization!) and back-transformed:
%[text]{"align":"center"} $Z = \\frac{1}{2}\\ln\\left(\\frac{1+r}{1-r}\\right) = \\mathrm{atanh}(r), \\qquad SE\_Z = \\frac{1}{\\sqrt{N-3}}$
dof = n - 2;
tR = rCorr * sqrt(dof) / sqrt(1 - rCorr^2);
pR = 2 * tcdf(-abs(tR), dof);
fprintf("t(%d) = %.2f, p = %.2g   (corr gives p = %.2g)\n", dof, tR, pR, pCorr);

zF = atanh(rCorr);                                % Fisher's z
seZ = 1 / sqrt(n - 3);
ci = tanh(zF + [-1 1] * norminv(0.975) * seZ);    % back-transform the interval
[~, ~, RL, RU] = corrcoef(age, nwbv);             % corrcoef gives the same interval
fprintf("95%% CI for r: [%.3f, %.3f]   (corrcoef: [%.3f, %.3f])\n", ci(1), ci(2), RL(1, 2), RU(1, 2));
%%
%[text] The test is hugely significant and the interval narrow. A tiny p-value only says that r differs from 0, not that the relationship is *strong* (the same lesson as for p-values and effect sizes last week).
%[text] **Do two correlations differ?** Two correlations from *independent* groups are compared after Fisher's z-transformation:
%[text]{"align":"center"} $z\_{emp} = \\frac{Z\_1 - Z\_2}{\\sqrt{\\frac{1}{N\_1-3} + \\frac{1}{N\_2-3}}}$
%[text] If $|z\_{emp}| \> z\_{crit}$ (1.96, two-sided, $\\alpha = .05$), the difference is significant ("same logic as a t-test"). Example: is the age-brain-volume correlation different in men and women?
male = T.M_F == "M";
rMen   = corr(age(male), nwbv(male));
rWomen = corr(age(~male), nwbv(~male));
nMen = sum(male);  nWomen = sum(~male);

zEmp = (atanh(rMen) - atanh(rWomen)) / sqrt(1 / (nMen - 3) + 1 / (nWomen - 3));
pDiff = 2 * normcdf(-abs(zEmp));
fprintf("men  : r = %.3f (n = %d)\n", rMen, nMen);
fprintf("women: r = %.3f (n = %d)\n", rWomen, nWomen);
fprintf("z_emp = %.2f, critical value = %.2f, p = %.3f\n", zEmp, norminv(0.975), pDiff);
%%
%[text] Both correlations are strong and negative. The difference is just beyond the critical value ($|z| = 2.06$, $p = .039$): men show a slightly *stronger* age-volume relationship in this sample. A borderline result like this deserves caution.
%[text] ## 1.7 Correlation is not causation
%[text] A correlation says that two variables vary together, and **nothing about why**. The slides' example: people who study more tend to have better grades, but good grades could also come from previous knowledge or logical thinking.
%[text] The same caution applies to our example. OASIS-1 is a **cross-sectional** study: each person was scanned once, so we compare *different people of different ages*, not the same person getting older. We cannot conclude from r = -.87 that "an individual's brain shrinks by this much per year": differences between generations (health, education, nutrition) are mixed into the relationship.
%[text] 
%[text] ## 2. Linear regression
%[text] 
%[text] ## 2.1 What is linear regression?
%[text] A correlation describes the relationship symmetrically. **Regression** **predicts** a *dependent variable* y from an *independent variable* (the predictor) x with a straight line:
%[text]{"align":"center"} $y = a + b \\cdot x$
%[text] - **a = intercept:** the predicted y at x = 0
%[text] - **b = slope:** how much y changes if x increases by one unit \
%[text] It only makes sense if x and y are correlated. Our example: **predict** **`nWBV`** **(y) from** **`Age`** **(x).**
%[text] ## 2.2 The method of least squares
%[text] Many lines could be drawn through the cloud. For each person, the **residual** is the vertical distance between the observed value $y\_i$ and the value $\\hat{y}\_i$ that the line predicts. Positive and negative residuals would cancel, so we **square** them and minimize the sum:
%[text]{"align":"center"} $\\min\_{a,b} \\sum\_i (y\_i - \\hat{y}\_i)^2 \\qquad \\hat{y}\_i = a + b\\, x\_i$
%[text] For one predictor the solution has a closed form: $b = r \\cdot s\_y / s\_x$ and $a = \\bar{y} - b\\bar{x}$.
b = rCorr * sy / sx;                              % slope from the correlation
a = mean(nwbv) - b * mean(age);                   % intercept: the line passes through the point of means

p = polyfit(age, nwbv, 1);                        % the ready-made version: [slope intercept]
fprintf("by hand : a = %.5f, b = %.6f\n", a, b);
fprintf("polyfit : a = %.5f, b = %.6f\n", p(2), p(1));
%%
%[text] **Try it yourself.** The next cell opens a window with two sliders (`uislider`). Move the intercept and the slope and try to push the **sum of squared residuals** (shown in the legend and the title) as low as you can. The orange segments are the residuals of all 416 persons. Start from the flat line: its sum of squares is $SS\_{tot}$ (section 2.4). (The two helper lines at the end of the file make the sliders work; no need to read them.)
fig = uifigure("Name", "Fit a line by hand", "Position", [100 100 760 580]);
gl = uigridlayout(fig, [3 2]);
gl.RowHeight = {"1x", 50, 50};
gl.ColumnWidth = {110, "1x"};

axUI = uiaxes(gl);
axUI.Layout.Row = 1;  axUI.Layout.Column = [1 2];
hold(axUI, "on")
segX = reshape([age'; age'; nan(1, n)], [], 1);   % NaN separates the segments of different persons
segY = reshape([nwbv'; repmat(mean(nwbv), 1, n); nan(1, n)], [], 1);
hRes  = plot(axUI, segX, segY, "Color", [0.95 0.65 0.4]);
scatter(axUI, age, nwbv, 10, [0.4 0.4 0.4], "filled")
xl = [min(age) max(age)];
hLine = plot(axUI, xl, mean(nwbv) * [1 1], "LineWidth", 2, "Color", [0 0.45 0.74]);
hold(axUI, "off")
ylim(axUI, [0.55 1.0]);  xlabel(axUI, "Age (years)");  ylabel(axUI, "nWBV")
legend(axUI, hLine, "Location", "northeast")

uilabel(gl, "Text", "intercept a");
sliderA = uislider(gl, "Limits", [0.5 1.1], "Value", mean(nwbv));
uilabel(gl, "Text", "slope b");
sliderB = uislider(gl, "Limits", [-0.004 0.002], "Value", 0);

sliderA.ValueChangingFcn = @(~, e) updateFit(e.Value, sliderB.Value, hLine, hRes, axUI, age, nwbv);
sliderB.ValueChangingFcn = @(~, e) updateFit(sliderA.Value, e.Value, hLine, hRes, axUI, age, nwbv);
updateFit(sliderA.Value, sliderB.Value, hLine, hRes, axUI, age, nwbv);
%%
%[text] After you have tried: the least-squares line has the smallest possible sum of squares.
ssBest = sum((nwbv - (a + b * age)).^2);
fprintf("sum of squared residuals of the least-squares line: %.3f\n", ssBest);
%%
%[text] Why is it the best line? We can check it directly: try many slopes, let each take its best intercept (a line through the means), and compute the sum of squared residuals for each.
slopes = linspace(2 * b, 0, 201);
ssCurve = zeros(size(slopes));
for k = 1:numel(slopes)
    aK = mean(nwbv) - slopes(k) * mean(age);
    ssCurve(k) = sum((nwbv - (aK + slopes(k) * age)).^2);
end

figure
tiledlayout(1, 2);
nexttile
plot(slopes, ssCurve, "LineWidth", 1.8)
xline(b, "--", "least squares", "LineWidth", 1.5);
xlabel("slope b"); ylabel("sum of squared residuals")

nexttile
scatter(age, nwbv, 10, [0.5 0.5 0.5], "filled", "MarkerFaceAlpha", 0.35)
hold on
xl = [min(age) max(age)];
plot(xl, a + b * xl, "k", "LineWidth", 1.8)
idx = randperm(n, 12);                            % 12 persons with their residuals drawn in
plot([age(idx) age(idx)]', [nwbv(idx) a + b * age(idx)]', "Color", [0.85 0.33 0.1], "LineWidth", 1.5)
scatter(age(idx), nwbv(idx), 22, [0.85 0.33 0.1], "filled")
hold off
xlabel("Age (years)"); ylabel("nWBV")
%%
%[text] Left: the sum of squares forms a bowl with its bottom exactly at the least-squares slope. Right: the regression line and the residuals (orange) of 12 randomly chosen persons.
%[text] *Why do we square?* (1) Otherwise positive and negative residuals cancel. (2) Large misses are punished more than small ones. (3) The squared version has a simple closed-form solution. The price: single outliers have a strong pull on the line.
%[text] ## 2.3 Interpretation: intercept, slope, prediction
%[text] The toolbox function for a linear model is `fitlm`; it gives estimates, standard errors, t-tests and R-squared in one object.
mdl = fitlm(age, nwbv)
%%
fprintf("slope b = %.5f per year (%.4f per decade)\n", mdl.Coefficients.Estimate(2), 10 * mdl.Coefficients.Estimate(2));
ages = [20; 50; 70; 90];
table(ages, predict(mdl, ages), VariableNames=["Age", "predicted_nWBV"])
%%
%[text] - **Slope:** with each additional year of age, `nWBV` is on average **0.0021 lower** (about 0.021 per decade). The slope is in "units of y per unit of x", so its size depends on the scales of the variables.
%[text] - **Intercept:** the prediction for age 0 (0.90). This is *not meaningful* here: nobody in the data is younger than 18. The intercept is the anchor of the line, not always a result to interpret.
%[text] - **Predictions** are only trustworthy **inside the range of the data** (18 to 96 years). Predicting far outside is *extrapolation*.
%[text] - A prediction is a *mean*: individual people scatter around it. \
%[text] 
%[text] ## 2.4 How good is the prediction? Explained variance, standard errors, confidence intervals
%[text] The quality of the predictor can be judged by how much of the variance of y it explains and how much **residual variance** is left:
%[text]{"align":"center"} $R^2 = 1 - \\frac{SS\_{res}}{SS\_{tot}}$
%[text] $SS\_{tot}$ is the total sum of squares around the *mean* of y (the error if we ignored x). $SS\_{res}$ is the sum of squared residuals around the *line*. $SS\_{reg}$ is the part the line explains, and $SS\_{tot} = SS\_{reg} + SS\_{res}$.
predicted = a + b * age;
res = nwbv - predicted;
ssTot = sum((nwbv - mean(nwbv)).^2);
ssRes = sum(res.^2);
ssReg = sum((predicted - mean(nwbv)).^2);

fprintf("SS_tot = %.3f | SS_res = %.3f | SS_reg = %.3f | SS_reg + SS_res = %.3f\n", ssTot, ssRes, ssReg, ssReg + ssRes);
fprintf("R^2 = 1 - SS_res/SS_tot = %.3f   (r^2 = %.3f, fitlm: %.3f)\n", 1 - ssRes / ssTot, rCorr^2, mdl.Rsquared.Ordinary);
fprintf("residual standard error = %.4f   (SD of nWBV itself: %.4f)\n", mdl.RMSE, sy);
%%
%[text] In each panel of the next figure, every segment is the distance of one person to a reference line; the legend gives the sum of the *squared* lengths: **left** the distance to the mean ($SS\_{tot}$), **middle** the distance to the regression line ($SS\_{res}$), **right** the distance between the regression line and the mean ($SS\_{reg}$, the explained part).
meanLine = repmat(mean(nwbv), n, 1);
xl = [min(age) max(age)];
figure
tiledlayout(1, 3);

nexttile                                          % left: points to the mean
segX = [age age nan(n, 1)]';  segY = [nwbv meanLine nan(n, 1)]';
scatter(age, nwbv, 9, [0.5 0.5 0.5], "filled", "MarkerFaceAlpha", 0.6)
hold on
h = plot(segX(:), segY(:), "Color", [0.85 0.33 0.1], "DisplayName", sprintf("SS_{tot} = %.3f", ssTot));
plot(xl, mean(nwbv) * [1 1], "k", "LineWidth", 1.8)
hold off
legend(h, "Location", "northeast", "Box", "off")
ylim([0.6 0.97]); xlabel("Age (years)"); ylabel("nWBV"); title("total variation: points to the mean")

nexttile                                          % middle: points to the regression line
segY = [nwbv predicted nan(n, 1)]';
scatter(age, nwbv, 9, [0.5 0.5 0.5], "filled", "MarkerFaceAlpha", 0.6)
hold on
h = plot(segX(:), segY(:), "Color", [0.85 0.33 0.1], "DisplayName", sprintf("SS_{res} = %.3f", ssRes));
plot(xl, a + b * xl, "k", "LineWidth", 1.8)
hold off
legend(h, "Location", "northeast", "Box", "off")
ylim([0.6 0.97]); xlabel("Age (years)"); title("unexplained: points to the line")

nexttile                                          % right: regression line to the mean
segY = [meanLine predicted nan(n, 1)]';
scatter(age, nwbv, 9, [0.5 0.5 0.5], "filled", "MarkerFaceAlpha", 0.25)
hold on
h = plot(segX(:), segY(:), "Color", [0 0.45 0.74], "DisplayName", sprintf("SS_{reg} = %.3f\nR^2 = %.3f", ssReg, ssReg / ssTot));
plot(xl, a + b * xl, "k", "LineWidth", 1.8)
plot(xl, mean(nwbv) * [1 1], "k--")
hold off
legend(h, "Location", "northeast", "Box", "off")
ylim([0.6 0.97]); xlabel("Age (years)"); title("explained: line to the mean")
%%
%[text] Using age as a predictor reduces the squared error from 1.50 to 0.36: **R^2 = .76**, the same as r^2. The **residual standard error** (the typical distance of a person from the line, 0.029) is about half of the original SD of `nWBV` (0.060).
%[text] **Standard error and confidence interval of the slope.** The test of H0 "b = 0" is a t-test with $df = N - 2$ and gives *exactly* the same t and p as the test of the correlation in 1.6.
slopeSE = mdl.Coefficients.SE(2);
slopeCI = coefCI(mdl);                            % rows: intercept, slope; columns: lower, upper
fprintf("SE of the slope = %.6f\n", slopeSE);
fprintf("t(%d) = %.2f   (same as the t of r: %.2f)\n", mdl.DFE, mdl.Coefficients.tStat(2), tR);
fprintf("95%% CI of the slope: [%.5f, %.5f]\n", slopeCI(2, 1), slopeCI(2, 2));
%%
%[text] **Two different bands around the line.** The slides mention that "95% of the data are 1.96 standard deviations around the mean" and a confidence interval. These are two different things:
%[text] - the **95% confidence band of the line** tells us how precisely we know the *line* (uses the standard error);
%[text] - the band **+-1.96 residual standard errors** tells us where about 95% of the *individual people* lie. \
xg = linspace(min(age), max(age), 200)';
[yg, yci] = predict(mdl, xg);                     % line and its 95% confidence interval
sRes = mdl.RMSE;

figure
scatter(age, nwbv, 10, [0.5 0.5 0.5], "filled", "MarkerFaceAlpha", 0.4)
hold on
fill([xg; flipud(xg)], [yg - 1.96 * sRes; flipud(yg + 1.96 * sRes)], [0 0.45 0.74], "FaceAlpha", 0.15, "EdgeColor", "none", ...
     "DisplayName", "+- 1.96 residual SE (about 95% of people)")
fill([xg; flipud(xg)], [yci(:, 1); flipud(yci(:, 2))], [0.85 0.33 0.1], "FaceAlpha", 0.6, "EdgeColor", "none", ...
     "DisplayName", "95% confidence band of the line")
plot(xg, yg, "k", "LineWidth", 1.5, "HandleVisibility", "off")
hold off
xlabel("Age (years)"); ylabel("nWBV")
legend("Location", "southwest", "Box", "off")
fprintf("share of the participants inside the wide band: %.3f\n", mean(abs(res) <= 1.96 * sRes));
%%
%[text] The orange confidence band is so narrow that it is hard to see: with 416 people we know the line very precisely. The wide band contains about 95% of the dots. The confidence interval concerns the *line* (the standard error shrinks with the sample size), the wide band concerns *people* (it does not shrink). It is the same distinction as between SD and SEM in week 3.
%[text] **Standardized slope (beta).** If we z-standardize both variables *before* the regression, the slope is called **beta**: it makes slopes comparable across variables. In simple regression, **beta = r**.
mdlZ = fitlm(zscore(age), zscore(nwbv));
fprintf("standardized slope beta = %.3f   (r = %.3f)\n", mdlZ.Coefficients.Estimate(2), rCorr);
%[text] 
%[text] ## 2.5 When can I use linear regression? Checking the assumptions
%[text] For regression the assumptions are checked on the **residuals**:
%[text] 1. **linearity:** the residuals scatter randomly around 0, with no curve
%[text] 2. **homoscedasticity:** the spread of the residuals is the same at all x
%[text] 3. **normality of the residuals:** Q-Q plot and the quantitative tests from last week \
figure
tiledlayout(1, 2);
nexttile
scatter(mdl.Fitted, mdl.Residuals.Raw, 12, "filled", "MarkerFaceAlpha", 0.6)
yline(0, "k");
xlabel("predicted nWBV"); ylabel("residual"); title("residuals against predicted values")
nexttile
qqplot(mdl.Residuals.Raw)
xlabel("expected z-value (normal)"); ylabel("observed residual"); title("Q-Q plot of the residuals")

binA = discretize(age, [17 40 60 80 100], "categorical", ["18-39", "40-59", "60-79", "80+"]);
eA = mdl.Residuals.Raw;
residualSpread = groupsummary(table(binA, eA), "binA", "std", "eA")
%%
%[text] - **Linearity:** the left plot shows a *mild* curve: the residuals are mostly positive in the middle and negative at both ends. Among the young, brain volume is almost flat, and the decline gets steeper later. A straight line is a decent but not perfect summary.
%[text] - **Homoscedasticity:** the residuals fan out: young participants (high predicted nWBV, right side) are close to the line, older ones scatter more. The SD of the residuals is about twice as large for the older groups. This is a *moderate* violation.
%[text] - **Normality:** the Q-Q plot follows the line except for deviations in the tails. The quantitative tests (H0 = the residuals are normal; small p = evidence against normality): \
e = mdl.Residuals.Raw;
[~, pAD] = adtest(e);
[~, pLF] = lillietest(e);
[~, pJB] = jbtest(e);
fprintf("Anderson-Darling p = %.3f | Lilliefors p = %.3f | Jarque-Bera p = %.3f | skewness = %.2f\n", pAD, pLF, pJB, skewness(e));
%%
%[text] The tests lie around the .05 line (MATLAB has no Shapiro-Wilk test, and the p-values are looked up in tables), so the departure from normality is mild. With a large sample, the t-tests and confidence intervals of the regression are fairly robust, so we would use the regression, but report the heteroscedasticity.
%[text] 
%[text] ## 3. Does the picture change in a subgroup? Participants with a CDR rating
%[text] We saw that a single line is not a perfect summary of the whole age range. One approach is an **age-specific analysis**: the natural subgroup in OASIS is the set of participants with a **clinical dementia rating** (CDR), which was only assessed in older participants (n = 235). We repeat the steps of section 2.
%[text] *Two cautions.* The subgroup is **part of** the whole sample, so the two analyses are not independent and we compare them *descriptively*. And it is not a random sample of the older population: it contains participants with and without dementia (CDR \> 0).
rated = ~isnan(T.CDR);
ageR = age(rated);  nwbvR = nwbv(rated);  cdrR = T.CDR(rated);

whoTable = table([n; sum(rated)], [min(age); min(ageR)], [max(age); max(ageR)], [mean(age); mean(ageR)], [std(age); std(ageR)], ...
                 [std(nwbv); std(nwbvR)], VariableNames=["n", "Age_min", "Age_max", "Age_mean", "Age_SD", "nWBV_SD"], ...
                 RowNames=["all participants", "with CDR rating"])
cdrCounts = groupcounts(table(cdrR), "cdrR")
%%
%[text] The rated participants are all older than 32, the average age is 72, and the **spread of age is only half as large** (SD of 12 instead of 25 years). The correlation depends on how much the variables vary in the sample.
%[text] Now the same analysis for both samples: correlation, least-squares line, R^2, residual standard error, standard error and confidence interval of the slope.
samples = {age, nwbv; ageR, nwbvR};
results = zeros(2, 10);
for i = 1:2
    m = fitlm(samples{i, 1}, samples{i, 2});
    cis = coefCI(m);
    results(i, :) = [m.NumObservations, corr(samples{i, 1}, samples{i, 2}), m.Rsquared.Ordinary, m.Coefficients.Estimate(1), ...
                     m.Coefficients.Estimate(2), m.Coefficients.SE(2), cis(2, 1), cis(2, 2), m.SST, m.RMSE];
end
format short g
comparison = array2table(results, VariableNames=["n", "r", "R2", "intercept", "slope", "SE_slope", "CI_lower", "CI_upper", "SS_tot", "residual_SE"], ...
                         RowNames=["all participants", "with CDR rating"])
format short
%%
%[text] - **The slope is steeper in the rated participants** (-0.0029 per year instead of -0.0021, about -0.029 per decade): the decline between 33 and 96 is faster than the average over the whole range 18 to 96 (which includes the almost flat young adults). The confidence intervals do not overlap.
%[text] - **r and R^2 are smaller** (r = -.72 and R^2 = .52, against -.87 and .76). But the **residual standard error** is almost the same (0.033 against 0.029): the line misses a typical person by about the same amount. What changed is the *total* variation $SS\_{tot}$, which is much smaller when we only look at older people. This is the **restriction of range** effect: r and R^2 depend on how much x varies in the sample.
%[text] - The **intercept** (0.96) is even less interpretable: nobody here is younger than 33. \
mdlAll = fitlm(age, nwbv);
mdlR = fitlm(ageR, nwbvR);
dem = cdrR > 0;
xlAll = [min(age) max(age)];  xlR = [min(ageR) max(ageR)];

figure
tiledlayout(1, 2);
nexttile
scatter(age, nwbv, 10, [0.5 0.5 0.5], "filled", "MarkerFaceAlpha", 0.5)
hold on
hL = plot(xlAll, predict(mdlAll, xlAll'), "k", "LineWidth", 1.8, ...
          "DisplayName", sprintf("all participants (n = %d)\nR^2 = %.2f", n, mdlAll.Rsquared.Ordinary));
hold off
xlim([15 100]); ylim([0.6 0.97]); xlabel("Age (years)"); ylabel("nWBV"); title("whole sample")
legend(hL, "Box", "off", "Location", "northeast")

nexttile
scatter(ageR(~dem), nwbvR(~dem), 12, "filled", "MarkerFaceAlpha", 0.6)
hold on
scatter(ageR(dem), nwbvR(dem), 12, "filled", "MarkerFaceAlpha", 0.7)
plot(xlR, predict(mdlR, xlR'), "k", "LineWidth", 1.8)
plot(xlR, predict(mdlAll, xlR'), "k--", "LineWidth", 1.4)
hold off
xlim([15 100]); ylim([0.6 0.97]); xlabel("Age (years)"); title("participants with a CDR rating")
legend("CDR = 0 (no dementia)", "CDR > 0 (dementia)", sprintf("rated only, R^2 = %.2f", mdlR.Rsquared.Ordinary), "line of the whole sample", ...
       "Box", "off", "Location", "northeast")
%%
%[text] The solid line (rated participants) is steeper than the dashed line of the whole sample. The participants **with dementia** lie mostly in the lower half of the cloud: within the rated group, brain volume depends not only on age but also on dementia status, a second predictor. That is the topic of the next session (multiple regression).
%[text] **Assumptions in the subgroup:** the same checks as in 2.5.
eR = mdlR.Residuals.Raw;
figure
tiledlayout(1, 2);
nexttile
scatter(mdlR.Fitted, eR, 12, "filled", "MarkerFaceAlpha", 0.6)
yline(0, "k");
xlabel("predicted nWBV"); ylabel("residual"); title("residuals against predicted values")
nexttile
qqplot(eR)
xlabel("expected z-value (normal)"); ylabel("observed residual"); title("Q-Q plot of the residuals")

binR = discretize(ageR, [32 70 80 100], "categorical", ["33-69", "70-79", "80+"]);
residualSpreadR = groupsummary(table(binR, eR), "binR", "std", "eR")
[~, pADr] = adtest(eR);  [~, pLFr] = lillietest(eR);  [~, pJBr] = jbtest(eR);
fprintf("subgroup: Anderson-Darling p = %.3f | Lilliefors p = %.3f | Jarque-Bera p = %.3f | skewness = %.2f\n", pADr, pLFr, pJBr, skewness(eR));
%%
%[text] - **Homoscedasticity:** in the subgroup the spread of the residuals is practically **equal across the age bands** (about 0.034, 0.032 and 0.034). The heteroscedasticity in the whole sample (0.019 to 0.021 for the young, 0.034 to 0.036 for the old) largely came from mixing very different age ranges.
%[text] - **Normality:** the Q-Q plot is close to the line with a few low values in the left tail, and the tests are again around the .05 line: the departure is mild. \
%[text] **What did the subgroup analysis teach us?**
%[text] - The slope (-0.0029 per year) describes the decline in older participants better than the whole-sample slope.
%[text] - r and R^2 are *not* properties of a relationship alone: they change with the range of the predictor. Compare slopes and residual standard errors, not only R^2.
%[text] - A subgroup is selected, not random: dementia status explains additional variation in brain volume, which leads us to multiple regression. \
%[text] 
%[text] ## 4. Summary
%[text] - **Covariance** measures how two variables vary together but depends on the units. **Pearson's r** = covariance / ($s\_x s\_y$) = the covariance of the z-scores (`corr`, range -1 to +1).
%[text] - **r^2** is the shared variance. Age and `nWBV`: r = -.87, r^2 = .76.
%[text] - A correlation requires equal-interval data, a **linear** relationship and **equal spread**. Check the scatter plot; use rank correlations (`corr(..., "Type", "Spearman")`) if the scale is ordinal.
%[text] - A correlation is tested with a **t-test** ($df = N-2$). Correlations are compared with **Fisher's z-transformation** (`atanh`), not the z-standardization.
%[text] - **Correlation is not causation**, and cross-sectional data compare different people, not one person over time.
%[text] - **Regression** predicts y from x with $y = a + bx$ by minimizing the **sum of squared residuals** (`polyfit`, `fitlm`). Predict only within the range of the data.
%[text] - $R^2 = 1 - SS\_{res}/SS\_{tot}$; the slope has a standard error and confidence interval (`coefCI`), and its t-test equals the test of r. **beta** (the slope of z-standardized variables) makes slopes comparable.
%[text] - Check the **residuals** for linearity, homoscedasticity and normality (plots, `qqplot`, `adtest`, `lillietest`, `jbtest`).
%[text] - A subgroup analysis can fit better (steeper slope, equal spread), but R^2 shrinks with the range of x (restriction of range). \
%[text] **Sources**
%[text] - Marcus, D. S. et al. (2007). Open Access Series of Imaging Studies (OASIS): Cross-sectional MRI data in young, middle aged, nondemented, and demented older adults. *Journal of Cognitive Neuroscience, 19*, 1498-1507.
%[text] - Slides: `05_CorrelationRegression.pptx` \
%[text] ## Helper for the sliders in section 2.2 (no need to read this)
function updateFit(intercept, slope, hLine, hRes, ax, age, nwbv)
    pred = intercept + slope * age;
    ss = sum((nwbv - pred).^2);
    n = numel(age);
    hLine.YData = intercept + slope * hLine.XData;
    hRes.YData = reshape([nwbv'; pred'; nan(1, n)], [], 1);
    hLine.DisplayName = sprintf("a = %.3f, b = %.5f", intercept, slope);
    title(ax, sprintf("sum of squared residuals = %.3f", ss))
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
