#####################################################################################
# Script adapted from
# https://alexanderetz.com/2015/08/09/understanding-bayes-visualization-of-bf/
#################################################################################

#d <- rbinom(1e2, size = 1, prob = 0.4)
#data = d; a1 = 6; b1 = 10; a2 = 20; b2 = 12; int = 0.1;

BFgif <- function(data, a1 = 10, b1 = 10, a2 = 10, b2 = 10, int = 0.1) {
    
    library(tidyverse)
    library(gganimate)
    library(animation)
    library(magick)
    library(purrr)
    
    # grid setup
    grid <- seq(from = 0, to = 1, length.out = 1e2)
    
    # size of data
    n <- length(data)
    
    post <-
        data.frame(theta = seq(from = 0, to = 1, length.out = 1e2) ) %>%
        mutate(
            # computing the likelihood of each data point
            like = sapply(1:nrow(.), function(i) prod(dbinom(
                data, size = 1, prob = theta[i], log = FALSE) ) ),
            like = like / max(like),
            # computing the marginal likelihood
            # prior model 1
            prior1 = dbeta(.$theta, a1, b1, log = FALSE),
            prior1 = prior1 / max(prior1),
            # for model 1
            marg1 = like * prior1,
            # prior model 2
            prior2 = dbeta(.$theta, a2, b2, log = FALSE),
            prior2 = prior2 / max(prior2),
            # and for model 2
            marg2 = like * prior2,
            # incremental bf
            bf = cumsum(marg1) / cumsum(marg2),
            # incremental frame length
            len = 1:nrow(.)
        ) %>%
        # replacing NaNs BFs by 1
        replace(., is.na(.), 1)
    
    # BF12 is the ratio of the marginals
    bf12 <- sum(post$marg1) / sum(post$marg2)
        
    # making first plot (prior and likelihood)
    p1 <- 
        post %>%
            select(-marg1, -marg2) %>%
            ggplot(aes(frame = len) ) +
            # plotting likelihood function
            geom_line(aes(x = theta, y = like), inherit.aes = FALSE, size = 1) +
            # plotting prior1
            geom_line(
                aes(x = theta, y = prior1),
                linetype = "dashed", col = "#016392", size = 1,
                inherit.aes = FALSE) +
            # plotting prior2
            geom_line(
                aes(x = theta, y = prior2),
                linetype = "dashed", col = "#c72e29", size = 1,
                inherit.aes = FALSE) +
            geom_point(aes(x = theta, y = like), size = 2.5) +
            geom_point(aes(x = theta, y = prior1), col = "#016392", size = 2.5) +
            geom_point(aes(x = theta, y = prior2), col = "#c72e29", size = 2.5) +
            # adds vertical line at each theta
            geom_segment(
                aes(x = theta, xend = theta, y = 0, yend = 1),
                linetype = "dotted") +
            theme_bw(base_size = 20, base_family = "Verdana") +
            ylab("") +
            xlab(expression(paste("Probability of heads ", theta) ) ) +
            ggtitle(
                paste0(
                    "Likelihood function for ", length(data), " coin flips \nand ",
                    sum(data), " heads"
                )
            )
    
    # making second plot (Unnormalised posterior density)
    p2 <- 
        p <- 
        post %>%
        ggplot(aes(frame = len) ) +
        # plotting marg1
        geom_line(
            aes(x = theta, y = marg1),
            linetype = "dashed", col = "#016392", size = 1,
            inherit.aes = FALSE) +
        # plotting marg2
        geom_line(
            aes(x = theta, y = marg2),
            linetype = "dashed", col = "#c72e29", size = 1,
            inherit.aes = FALSE) +
        geom_point(aes(x = theta, y = marg1), col = "#016392", size = 2.5) +
        geom_point(aes(x = theta, y = marg2), col = "#c72e29", size = 2.5) +
        # adds vertical line at each theta
        geom_segment(
            aes(x = theta, xend = theta, y = 0, yend = 1),
            linetype = "dotted") +
        theme_bw(base_size = 20, base_family = "Verdana") +
        ylab("") +
        xlab(expression(paste("Probability of heads ", theta) ) ) +
        ggtitle("Unnormalised posterior density")
    
    # making third plot (cumulative functions)
    p3 <- 
        post %>%
        mutate(cumsum1 = cumsum(marg1), cumsum2 = cumsum(marg2) ) %>%
        ggplot(aes(frame = len) ) +
        # plotting cumulative marginal for model1
        geom_line(
            aes(x = theta, y = cumsum1),
            linetype = "dashed", col = "#016392", size = 1,
            inherit.aes = FALSE) +
        # plotting cumulative marginal for model2
        geom_line(
            aes(x = theta, y = cumsum2),
            linetype = "dashed", col = "orangered3", size = 1,
            inherit.aes = FALSE) +
        geom_point(aes(x = theta, y = cumsum1), col = "#016392", size = 2.5) +
        geom_point(aes(x = theta, y = cumsum2), col = "#c72e29", size = 2.5) +
        # adds vertical line at each theta
        geom_segment(
            aes(x = theta, xend = theta, y = 0, yend = max(cumsum1) ),
            linetype = "dotted") +
        theme_bw(base_size = 20, base_family = "Verdana") +
        ylab("") +
        xlab(expression(paste("Probability of heads ", theta) ) ) +
        ggtitle("")
    
    gganimate(
        p1, filename = "bf1.gif",
        title_frame = FALSE, interval = int,
        ani.width = 600, ani.height = 600)
    
    gganimate(
        p2, filename = "bf2.gif",
        title_frame = FALSE, interval = int,
        ani.width = 600, ani.height = 600)
    
    gganimate(
        p3, filename = "bf3.gif",
        title_frame = FALSE, interval = int,
        ani.width = 600, ani.height = 600)
    
    ########################################################################
    # Making fourth plot - BF pizza plot
    ####################################################
    
    pizza <- 
        post %>%
        mutate(
            M1 = (bf) / (bf + 1),
            M2 = 1 - M1) %>%
        gather(hyp, BF, M1:M2) %>%
        arrange(len)
    
    animation::saveGIF({
        for (i in unique(pizza$len) ) {
            
            p <- 
                ggplot(pizza[pizza$len == i, ], aes(x = "", y = BF, fill = hyp, frame = len) ) +
                geom_bar(width = 0.25, stat = "identity", show.legend = FALSE) +
                coord_polar(theta = "y") +
                geom_text(
                    #data = post[post$len == i, ],
                    aes(
                        x = 0, y = 0,
                        label = paste0("BF12 = ", round(bf12, 2) )
                    ),
                    inherit.aes = FALSE, parse = FALSE, size = 7.5) +
                theme_void() +
                scale_fill_manual(values = c("#016392", "#c72e29") )
            
            print(p)
        }
    },
        movie.name = "pizza.gif", interval = int,
        ani.width = 600, ani.height = 600)
    
    #####################################################################################
    # Read the four plots and append them together
    # https://gist.github.com/expersso/944f3d4aad15f71b192fff254d4ac5b9
    #########################################################################
    
    # left panel
    map2(
        "bf2.gif" %>%
            image_read() %>%
            as.list(),
        "bf1.gif" %>%
            image_read() %>%
            as.list(),
        ~image_append(c(.x, .y), stack = TRUE) ) %>%
        lift(image_join)(.) %>%
        image_write("result1.gif")
    
    # right panel
    map2(
        "bf3.gif" %>%
            image_read() %>%
            as.list(),
        "pizza.gif" %>%
            image_read() %>%
            as.list(),
        ~image_append(c(.x, .y), stack = TRUE) ) %>%
        lift(image_join)(.) %>%
        image_write("result2.gif")
    
    # total plot
    map2(
        "result1.gif" %>%
            image_read() %>%
            as.list(),
        "result2.gif" %>%
            image_read() %>%
            as.list(),
        ~image_append(c(.x, .y), stack = FALSE) ) %>%
        lift(image_join)(.) %>%
        image_write("result.gif")
    
    # removing intermediate files
    c("bf1.gif", "bf2.gif", "bf3.gif", "pizza.gif", "result1.gif", "result2.gif") %>% walk(unlink)
    
}

# generating some data
d <- rbinom(1e2, size = 1, prob = 0.45)

# using the function
BFgif(d, a1 = 6, b1 = 10, a2 = 20, b2 = 12, int = 0.1)

##############################################################################
# BF pizza plot
############################################################

pizzaBF <- function(BF10) {
    
    BF10 <- BF10 / (BF10 + 1)
    BF01 <- 1 - BF10
    d <- data.frame(hyp = c("H1", "H0"), bf = c(BF10, BF01) )
    
    print(
        ggplot(d, aes(x = "", y = bf, fill = hyp ) ) +
            geom_bar(width = 1, stat = "identity") +
            coord_polar(theta = "y") +
            theme_void() +
            scale_fill_grey(start = 0.25, end = 0.75) +
            theme(legend.title = element_blank() )
    )
    
}

pizzaBF(BF10 = 6.18)
