# packages
library(knitr)
library(glue)
library(tidyverse)
library(targets)
library(tarchetypes)
library(ggtext)
library(ragg)
library(patchwork)
library(future)
library(furrr)
library(future.callr)

# theme
custom_theme <- function() {
  theme_classic(base_family = "Roboto", base_size = 16) +
  theme(
    legend.background = element_blank(),
    axis.line = element_blank(),
    plot.title.position = "plot"
  )
}

theme_set(custom_theme())

# globals
HITS_BLUE <- "#1E4287"
HITS_GREEN <- "#019050"
HITS_MAGENTA <- "#c3006b"
HITS_YELLOW <- "#ffcc00"
HITS_COLORS <- c(HITS_BLUE, HITS_GREEN, HITS_MAGENTA, HITS_YELLOW)
binary_colors <- c(HITS_BLUE, HITS_MAGENTA)

