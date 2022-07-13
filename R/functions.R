# Functions
#### general
compute_sequence <- function(path) {
  tln1_fasta <- seqinr::read.fasta(path, seqtype = "AA")[[1]]
  PIs <- tibble(
    res = unique(tln1_fasta),
    PI = future_map_dbl(res, seqinr::computePI))

  tibble(
    i = 1:length(tln1_fasta),
    res = c(tln1_fasta)) %>%
    left_join(PIs) %>%
    mutate(
      PI_window_7 = zoo::rollapply(res,
                                   width = 7,
                                   FUN = seqinr::computePI,
                                   partial = TRUE))
}

#### general distance data
read_distance_csvs <- function(paths) {
  read_csv(paths,
           col_names = c("i", "j", "r"),
           col_types = "iid",
           id = "frame")
}



#### rotsample ####
read_rotsample_distance_matrices <- function(path) {
  message(glue("Working on {path}"))
  angle <- str_extract(path,"(?<=angle_)\\d+")
  run <- as.integer(str_extract(path, "(?<=_run)\\d+"))
  fs::dir_ls(path, glob = "*.csv") |>
    read_distance_csvs() |>
    mutate(frame = parse_integer(str_extract(basename(frame), ".+(?=\\.dat\\.csv)")),
           j = factor(j),
           angle = as.integer(angle),
           run = run)
}

combine_f0f1_matrices_per_run_angle <- function(paths) {
  future_map_dfr(paths, possibly(read_rotsample_distance_matrices, tibble(frame = NA)))
}



summarize_interacting_run_angle <- possibly(function(distances, CUTOFF) {
  distances |>
    group_by(run, frame, i, angle) |>
    summarise(n_pip = sum(r <= CUTOFF)) |>
    ungroup()
}, tibble(frame = NA))

summarize_interacting <- function(distances, CUTOFF) {
  distances |>
    group_by(run, frame, i, angle) |>
    summarise(n_pip = sum(r <= CUTOFF)) |>
    ungroup()
}

combine_dists <- function(distances, run) {
  runs <- 1:N
  runs <- set_names(runs)
  map_dfr(runs, .id = "run", function(run){
    path <- glue("data/derived/f0f1_rot_sample_dists_run{run}.rds")
    read_rds(path)
    }) |>
    mutate(across(run, as.integer))
    # write_rds("data/derived/f0f1_rot_sample_dists.rds")
}

combine_interacting <- function(runmax) {
  runs <- 1:runmax
  runs <- set_names(runs)
  map_dfr(runs, .id = "run", function(run){
    path <- glue("data/derived/f0f1_rot_sample_interacting_run{run}.rds")
    read_rds(path)
  }) %>%
    mutate(across(run, as.integer)) %>%
    write_rds("data/derived/f0f1_rot_sample_interacting.rds")
}


#### pulling
read_pulling_dist_matrices <- function(path) {
  message(glue("Working on {path}"))

  fs::dir_ls(path, glob = "*.csv") %>%
    map_dfr(read_csv,
                   col_names = c("i", "j", "r"),
                   col_types = "iid",
                   .id = "frame") %>%
    mutate(frame = parse_integer(str_extract(basename(frame),
                                             ".+(?=\\.dat\\.csv)")),
           j = factor(j))
}

parse_pullf_xvg <- function(path) {
        path %>%
          read_lines(skip_empty_rows = TRUE) %>%
          grep("\t", ., value = TRUE) %>%
          str_replace("@", "#") %>%
          read_table(col_names = c("time", "value"),
                     comment = "#",
                     col_types = "dd")
}


#### ferm ####
read_ferm_distance_matrices <- function(path) {
  message(glue("Working on {path}"))
  run <- as.integer(str_extract(path, "(?<=run_)\\d+"))
  fs::dir_ls(path, glob = "*.csv") |>
    read_distance_csvs() |>
    mutate(frame = parse_integer(str_extract(basename(frame), ".+(?=\\.dat\\.csv)")),
           j = factor(j),
           run = run)
}

# combine_ferm_matrices_per_run <- function(paths) {
#   future_map_dfr(paths, read_ferm_distance_matrices)
# }

summarize_interacting_run <- function(df, CUTOFF) {
  df %>%
    group_by(run, frame, i) %>%
    summarise(n_pip = sum(r <= CUTOFF)) %>%
    ungroup()
}


#### plotting ####
sem <- function(x) sd(x) / sqrt(length(x))
