prior_scales <- function(prior, ...){
    
    ###############################################################################
    # https://www.r-bloggers.com/priors-on-odds-and-probability-of-success/
    ###########################################################################
    if (!require("LaplacesDemon")) install.packages("LaplacesDemon")
    library(LaplacesDemon)
    
    # helper function for conversion and Jacobian
    prob2Lo <- function(prob) log(prob / (1 - prob) )
    Lo2prob <- function(Lo) exp(Lo) / (1 + exp(Lo) )
    Jprob2Lo <- function(prob) prob * (1 - prob)
    JLo2prob <- function(Lo) (exp(Lo) + 1)^2 / exp(Lo)
    
    # wrapper for Jacobian
    dprob2dLo <- function(Lo, dprob, log = FALSE){
        prob <- Lo2prob(Lo)
        if (log) {dprob(prob) + log(Jprob2Lo(prob) )
        } else dprob(prob) * Jprob2Lo(prob)
    }
    
    dLo2dprob <- function(prob, dLo, log = FALSE){
        Lo <- prob2Lo(prob)
        if (log) {dLo(Lo) + log(JLo2prob(Lo) )
        } else dLo(Lo) * JLo2prob(Lo)
    }
    
    # two-columns plot
    # par(mfrow = c(1, 2) )
    
    # extracting the distribution and its arguments
    prior_type <- get(paste0("d", sub("\\(.*", "", prior) ) )
    prior_args <- gsub(".*\\((.*)\\).*", "\\1", prior)
    
    # plotting prior in log-odds scale
    Lo <- seq(-10, 10, 0.1)
    dLo <- eval(parse(text = paste("prior_type(Lo,", prior_args, ")") ) )
    plot(x = Lo, y = dLo, type = "l",
        col = "steelblue", lwd = 2, main = prior, xlab = "log-odds", ylab = "")
    
    # plotting prior in proba scale
    prob <- seq(0, 1, 0.01)
    dprob <- dLo2dprob(prob,
        dLo = function(Lo) eval(parse(text = paste("prior_type(prob,", prior_args, ")") ) ) )
    plot(x = prob, y = dprob, type = "l",
        col = "steelblue", lwd = 2, main = prior, xlab = "probability", ylab = "")
    
}

dens(rexp(1e5,1))
dens(plogis(rexp(1e5,5)))

dens(rcauchy(1e5,1))
dens(plogis(rcauchy(1e5,5)))
