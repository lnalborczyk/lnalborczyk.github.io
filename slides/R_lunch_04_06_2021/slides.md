<style>

iframe {
  position: absolute;
  top: 70%;
  left: 50%;
  -webkit-transform: translateX(-50%) translateY(-50%);
  transform: translateX(-50%) translateY(-50%);
  <!--
  min-width: 150vw;
  min-height: 100vh;
  z-index: -1000;
  -->
  overflow: hidden;
}

</style>

A priori power analyses using simulation
========================================================
author: Ladislas Nalborczyk
date: Univ. Grenoble Alpes, CNRS, LPNC (France) • Ghent University (Belgium)
autosize: true
transition: none
width: 1600
height: 1000
css: css-file.css

Statistical power
========================================================
incremental: false
type: lineheight



<!-- For syntax highlighting -->
<link rel="stylesheet" href="github.css">

In the Null Hypothesis Significance Testing (NHST) framework, statistical power is defined as the probability of rejecting the hypothesis of null effect when this hypothesis is indeed false.

<img src="errors.png" title="plot of chunk unnamed-chunk-1" alt="plot of chunk unnamed-chunk-1" width="900px" style="display: block; margin: auto;" />

Statistical power, more broadly
========================================================
incremental: true
type: lineheight

A broader definition of statistical power (from [Kruschke, 2015](http://www.indiana.edu/~kruschke/DoingBayesianDataAnalysis/)): *Statistical power is the probability of achieving the goal of a planned empirical study, if a suspected underlying state of the world is true*.

These goals might include (non-exhaustively):

* Obtaining a p-value inferior to $\alpha$ (where $\alpha$ is your favourite significance level)
* Obtaining a Bayes Factor (or a Likelihood Ratio) superior to some threshold $T$
* Rejecting a null value of a parameter (e.g., by showing that a region of practical equivalence (ROPE) around the null value excludes the 95% CI/CrI)
* Affirming a predicted value of a parameter (e.g., by showing that a ROPE around the predicted value includes the 95% CI/CrI)
* Achieving some level of precision in the estimate of a parameter (e.g., the width of the 95% CI/CrI)

Why simulation ?
========================================================
incremental: true
type: lineheight

Why the hell would we need to use simulation ? We already have [G*Power](http://www.gpower.hhu.de) ! 

YES, but what about designs that are not covered ? And what about other *goals* ? In other words, simplicity of use comes at the price of *flexibility*: you can compute power for a limited set of designs and for a limited set of goals (usually only for significance).

<img src="bean.gif" title="plot of chunk bean" alt="plot of chunk bean" width="600px" style="display: block; margin: auto;" />

General steps to conduct power analyses via simulation
========================================================
incremental: true
type: lineheight

Four (five) general steps for (Bayesian) power analysis (from [Kruschke, 2015](http://www.indiana.edu/~kruschke/DoingBayesianDataAnalysis/)):

1. (Generate representative parameter values from hypothesis)
2. Generate a random sample of data from the hypothetical parameter values
3. Retrieve the (posterior distribution of the) estimate of interest based on the fake dataset
4. Tally whether goal was attained
5. Repeat many (many) times

A gentle introduction to power analysis via simulation
========================================================
incremental: true
type: lineheight

We first write a short function that, given a sample size `n` (per group) and a standardised effect size `d`, outputs the p-value issued from a two-sample t-test.


```r
library(tidyverse)

sim_power <- function(n, d) {
    
    x <- rnorm(n, mean = 0, sd = 1)
    y <- rnorm(n, mean = d, sd = 1)
    p <- t.test(x, y)$p.value
    
    return(p)
    
}
```


```r
sim_power(n = 36, d = 0.5)
```

```
[1] 0.003069109
```

A gentle introduction to power analysis via simulation
========================================================
incremental: false
type: lineheight


```r
# replicating the sim_power function 1e4 times
results <- replicate(1e4, sim_power(n = 36, d = 0.5) )

# plotting it
results %>% qplot + theme_minimal(base_size = 20) + xlab("p-values")
```

<img src="slides-figure/unnamed-chunk-4-1.png" title="plot of chunk unnamed-chunk-4" alt="plot of chunk unnamed-chunk-4" style="display: block; margin: auto;" />

```r
# what proportion of p-values are below .05 ?
sum(results < .05) / length(results)
```

```
[1] 0.5476
```

Aparté: the distribution of p-values
========================================================
incremental: true
type: lineheight

<iframe src="https://barelysignificant.shinyapps.io/pdist/" height="100%" width="100%"></iframe>

A gentle introduction to power analysis via simulation
========================================================
incremental: false
type: lineheight

Approximate power for different sample sizes (from n = 20 to n = 200) and effect sizes (from d = 0.1 to d = 1) using `dplyr`.


```r
# set up parameters
crossing(n = seq(20, 200, 10), d = seq(0.1, 1, 0.1) ) %>%
    # for each sample size and effect size
    group_by(n, d) %>%
    # add observations
    expand(reps = 1:n) %>%
    ungroup %>%
    # add 1000 simulations
    crossing(sim = 1:1e3) %>%
    # generate data
    mutate(x = rnorm(n(), mean = 0, sd = 1), y = rnorm(n(), mean = d, sd = 1) ) %>%
    # for each sample size, effect size, and simulated dataset
    group_by(n, d, sim) %>%
    # compute a t-test and extract the p-value
    mutate(p = t.test(x, y, data = .)$p.value) %>%
    ungroup %>%
    # for each sample size and effect size
    group_by(n, d) %>%
    # compute power
    summarise(power = 1 - sum(p > 0.05) / n() ) %>%
    ungroup
```

A gentle introduction to power analysis via simulation
========================================================
incremental: false
type: lineheight





<img src="animation.gif" title="plot of chunk unnamed-chunk-8" alt="plot of chunk unnamed-chunk-8" width="1100px" style="display: block; margin: auto;" />

Another example using the ROPE + HDI procedure
========================================================
incremental: true
type: lineheight

This procedure makes it possible to either *accept* or *reject* a null value. The *Region of Practical Equivalence* defines the range of values that we consider as *practically equivalent* to the null value under examination. The following figure summarises potential outcomes of this procedure (from [Kruschke, 2018](https://journals.sagepub.com/doi/abs/10.1177/2515245918771304)).

<img src="hdi_rope.png" title="plot of chunk unnamed-chunk-9" alt="plot of chunk unnamed-chunk-9" width="900px" style="display: block; margin: auto;" />

Another example using the ROPE + HDI procedure
========================================================
incremental: false
type: lineheight

Let's consider the usual 2x2 between-subject design where we are interested in the interaction effect $\beta_{12}$.

$$
\begin{align}
y_{i} &\sim \mathrm{Normal}(\mu_{i}, \sigma) \\
\mu_{i} &= \alpha + \beta_{1} \cdot x_{1i} + \beta_{2} \cdot x_{2i} + \beta_{12} \cdot x_{1i} x_{2i} \\
\end{align}
$$

We are going to i) *generate* data that satisfy some constraints, ii) *compute* the posterior distribution on the parameter of interest, iii) *tally* whether the 95% HDI is either completely outside or inside the ROPE and iv) *repeat* this procedure many times.

Another example using the ROPE + HDI procedure
========================================================
incremental: false
type: lineheight

$$
\begin{align}
y_{i} &\sim \mathrm{Normal}(\mu_{i}, \sigma) \\
\mu_{i} &= \alpha + \beta_{1} \cdot x_{1i} + \beta_{2} \cdot x_{2i} + \beta_{12} \cdot x_{1i} x_{2i} \\
\end{align}
$$


```r
sim_data <- function(n, beta12) {
    
    # set coefficients
    alpha <- 10
    beta1 <- 0.3
    beta2 <- - 0.5
    
    # generate design structure
    x1 <- c(rep(c(0), n / 2), rep(c(1), n / 2) )
    x2 <- rep(c(rep(c(0), n / 4), rep(c(1), n / 4) ), 2)
    sigma <- rnorm(n, 0, sd = 1) # random noise, with standard deviation of 1
    
    # generate data using the regression equation
    y <- alpha + beta1 * x1 + beta2 * x2 + beta12 * x1 * x2 + sigma
    
    # join the variables in a common dataframe
    data <- data.frame(cbind(x1, x2, y) )
    
    # ouput this dataframe
    return(data)
    
}
```

Another example using the ROPE + HDI procedure
========================================================
incremental: false
type: lineheight


```r
# defining the combinations of parameters values to explore
grid <- crossing(n = seq(20, 200, 10), sim = 1:1e3)

# hypothesised value for beta12
beta12 <- 1.1

# initialising the results dataframe
res <- data.frame(n = numeric(), beta12 = numeric(), lower = numeric(), upper = numeric() )

for (i in 1:nrow(grid) ) {
    
    # generating data
    df <- sim_data(n = grid$n[i], beta12 = beta12)
    
    # fitting the model
    BF <- BayesFactor::lmBF(
        y ~ 1 + x1 * x2, data = df,
        posterior = TRUE, iterations = 1e3, progress = FALSE
        )
    
    # retrieving the posterior samples
    samples <- BF[, 4]
    
    # computing the 95% credible interval
    CrI <- quantile(samples, probs = c(0.025, 0.975) )

    # storing the results
    res[i, ] <- cbind(grid$n[i], beta12, CrI[1], CrI[2])
    
}
```

Another example using the ROPE + HDI procedure
========================================================
incremental: false
type: lineheight


```r
# defining the ROPE
rope <- c(-.1, .1)

# approximating the power function
res %>%
    mutate(
        success = case_when(
            lower < min(rope) & upper < min(rope) ~ 1,
            lower > min(rope) & upper < max(rope) ~ 1,
            lower > min(rope) & upper > max(rope) ~ 1,
            TRUE ~ 0
            )
        ) %>%
    group_by(n, beta12) %>%
    summarise(power = mean(success) ) %>%
    ungroup %>%
    # plotting it
    ggplot(aes(x = n, y = power, group = beta12, fill = beta12) ) +
    geom_hline(yintercept = 0.8, linetype = 2) +
    geom_area(alpha = 0.5) +
    geom_line(aes(colour = beta12), size = 1) +
    geom_point(shape = 21, size = 3) +
    xlab("Sample size") +
    ylab("Statistical power") +
    theme_minimal(base_size = 20) +
    theme(legend.position = "none")
```

Another example using the ROPE + HDI procedure
========================================================
incremental: false
type: lineheight

<img src="slides-figure/unnamed-chunk-13-1.png" title="plot of chunk unnamed-chunk-13" alt="plot of chunk unnamed-chunk-13" style="display: block; margin: auto;" />

Planning for precision
========================================================
incremental: false
type: lineheight

At what sample size do correlations stabilize ? ([Schönbrodt & Perugini, 2013](https://www.sciencedirect.com/science/article/abs/pii/S0092656613000858))

<img src="precision.png" title="plot of chunk unnamed-chunk-14" alt="plot of chunk unnamed-chunk-14" width="1200px" style="display: block; margin: auto;" />

Planning for precision
========================================================
incremental: true
type: lineheight

*A related but more important question is that of measurement precision: given some priors and a certain number of participants, how close can we get to the unknown population value (Maxwell et al., 2008; Schönbrodt & Perugini, 2013; Peters & Crutzen, 2018) ?*

Basically, planning for precision involves first defining a *Region of Practical Equivalence* (ROPE), or equivalently, the *Smaller Effect Size Of Interest* (SESOI). Let's say for instance, effect sizes in the [-0.1, 0.1] interval on the scale of the standardised effect size. Then, we plan for a predefined level of precision (e.g., the width of the 95% CrI), let's say 80% of the width of the ROPE (as suggested by [Kruschke, 2015](http://www.indiana.edu/~kruschke/DoingBayesianDataAnalysis/)), that is, a precision of 0.16.

See this blogpost on [basic statistics](https://garstats.wordpress.com/2018/08/27/precision/), this [paper](https://journals.lww.com/epidem/Fulltext/2018/09000/Planning_Study_Size_Based_on_Precision_Rather_Than.1.aspx) by Rothman & Greenland (2018), as well as a [package](https://github.com/malcolmbarrett/precisely) and a [shiny app](https://malcolmbarrett.shinyapps.io/precisely/) based on this paper.

Take-home messages, further resources
========================================================
incremental: true
type: lineheight

<link rel="stylesheet" href="http://maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css">
<link rel="stylesheet" href="https://cdn.rawgit.com/jpswalsh/academicons/master/css/academicons.min.css">

<link rel = "stylesheet" href = "css/font-awesome.css"/>
<link rel = "stylesheet" href = "css/academicons.css"/>

* Statistical power can be defined as *the probability of achieving the goal of a planned empirical study, if a suspected underlying state of the world is true*

* Simulation can be used to approximate this probability in virtually any kind of design and for any kind of goal

* Four steps: i) **generate** data ii) **estimate** the parameter of interest, iii) **tally** whether goal is attained iv) **repeat** many times

[This blogpost](https://cognitivedatascientist.com/2015/12/14/power-simulation-in-r-the-repeated-measures-anova-5/) uses a similar approach to approximate power in repeated measures ANOVA designs. See also this [vignette](https://cran.r-project.org/web/packages/paramtest/vignettes/Simulating-Power.html) from the `paramtest` package, and this [blogpost on power simulations](http://disjointedthinking.jeffhughes.ca/2017/09/power-simulations-r/). Finally, this [blogpost](http://www.imachordata.com/linear-model-power-analysis-with-dplyr/) explains how to run power simulations using `dplyr` whereas [this one](https://gitlab.com/vuorre/bayesplan) presents a worklflow for Bayesian sample size planning with `brms`.

<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.1.1/jquery.min.js"></script>

<script>

for(i=0;i<$("section").length;i++) {
if(i==0) continue
$("section").eq(i).append("<p style='font-size:xx-large;position:fixed;right:200px;bottom:50px;'>" + i + "</p>")
}

</script>
