logit_dotplot <- function(x, y, xlab, ylab) {
    
    # inspired from: https://recology.info/2012/01/logistic-regression-barplot-fig/
    # and: http://rpubs.com/kohske/dual_axis_in_ggplot2
    
    # NB: x should be a continuous predictor
    # NB: y should be a dichotomic outcome
    
    library(tidyverse)
    library(gtable)
    library(grid)
    
    if (length(unique(y) ) > 2)
        
        stop("\n y should be a dichotomic outcome \n")
    
    d <- data.frame(x = x, y = y)
    
    a <- 
        d %>%
        ggplot(aes(x = x, y = y) ) +
        geom_smooth(
            method = "glm",
            method.args = list(family = "binomial"),
            se = FALSE, color = "black") +
        geom_dotplot(
            data = d[d$y == 0, ],
            stackdir = "up",
            binwidth = 0.5, dotsize = 1, alpha = 0.2,
            show.legend = FALSE) +
        scale_x_continuous(limits = range(d$x) ) +
        theme_bw(base_size = 12) +
        labs(x = xlab, y = ylab)
    
    
    b <-
        d %>%
        ggplot(aes(x = x, y = y) ) +
        geom_dotplot(
            data = d[d$y == 1, ],
            stackdir = "down",
            binwidth = 0.5, dotsize = 1, alpha = 0.2,
            show.legend = FALSE) +
        scale_x_continuous(limits = range(d$x) ) +
        scale_y_continuous(trans = "reverse", limits = c(1, 0) ) +
        theme(
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(),
            axis.text.y = element_blank(),
            axis.text.x = element_blank(),
            axis.ticks = element_blank(),
            panel.border = element_blank(),
            panel.background = element_blank() )
    
    # extract gtable
    g1 <- ggplot_gtable(ggplot_build(a) )
    g2 <- ggplot_gtable(ggplot_build(b) )
    
    # overlap the panel of 2nd plot on that of 1st plot
    pp <- c(subset(g1$layout, name == "panel", se = t:r) )
    
    g <-
        gtable_add_grob(
            g1, g2$grobs[[which(g2$layout$name == "panel")]],
            pp$t, pp$l, pp$b, pp$l)
    
    # plot a new viewports
    vp = viewport(width = 1, height = 1, x = 0.5, y = 0.5)
    pushViewport(vp)
    grid.draw(g)
    upViewport()
    
}
