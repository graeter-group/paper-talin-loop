source("R/globals.R")
source("R/functions.R")

tar_option_set(memory = "transient")

plan(callr)


list(
#### globals ####
  tar_target(
    data_path_prefix,
    "/hits/fast/mbm/buhrjk/master/"
  ),
  tar_target(
    CUTOFF, 0.25
  ),
  tar_target(
    path_sequence,
    {
      prefix <- data_path_prefix
      glue("{prefix}/tln1-data/ferm.fasta")
    },
    format = "file"
  ),
  tar_target(
    sequence,
    compute_sequence(path_sequence)
  ),
  tar_target(
    ferm_annotation,
    tribble(
      ~imin, ~imax, ~domain,
      1, 84, "f0",
      85, 207, "f1",
      135, 168, " ",
      208, 309, "f2",
      310, 400, "f3"
    )
  ),
  tar_target(
    ferm_colors,
    c(
      `f0` = "#89b77a",
      `f1` = "#55b4dc",
      ` ` = "#0088c2",
      `f2` = "#ffe07d",
      `f3` = "#da7da6"
    )
  ),
  tar_target(
    bool_colors,
    c(`FALSE` = HITS_MAGENTA,
      `TRUE` = HITS_BLUE)
  ),
  tar_target(
    ferm_pip_sites,
    tribble(
      ~ri,
      272,
      316,
      324,
      342,
      343
    )
  ),


#### rotsample ####
  tar_target(
    # manually invalidated, does not watch the filesystem
    paths_f0f1_rot_sample_runs,
    {
      prefix <- data_path_prefix
      setup <- crossing(
        run = 1:6,
        angles = seq(0, 354, by = 6)
      )
      paths <- glue("{prefix}/tln1_f0f1_rot_sample/f0f1_rot_sample_run{setup$run}/angle_{setup$angles}/conan/matrices/filtered")
      paths
    }
  ),
  tar_target(
    f0f1_rot_sample_distances_per_run,
    combine_f0f1_matrices_per_run_angle(paths_f0f1_rot_sample_runs),
    pattern = map(paths_f0f1_rot_sample_runs)
  ),
  tar_target(
    f0f1_rot_sample_run1,
    f0f1_rot_sample_distances_per_run,
    pattern = slice(f0f1_rot_sample_distances_per_run, index = 1)
  ),
  tar_target(
    f0f1_rot_sample_interacting_per_run,
    summarize_interacting_run_angle(f0f1_rot_sample_distances_per_run, CUTOFF),
    pattern = map(f0f1_rot_sample_distances_per_run)
  ),
  tar_target(
    f0f1_rot_sample_distances,
    bind_rows(f0f1_rot_sample_distances_per_run)
  ),
  tar_target(
    interacting,
    bind_rows(f0f1_rot_sample_interacting_per_run)
  ),
  tar_target(
    first_frames,
    interacting |>
      group_by(run, angle, frame) |>
      summarise(n_i = sum(n_pip > 0)) |>
      mutate(cs = cumsum(n_i)) |>
      filter(cs > 0) |>
      group_by(run, angle) |>
      summarise(first_frame = min(frame))
  ),
  tar_target(
    docked,
    interacting |>
      left_join(first_frames) |>
      distinct(run, angle, docked = !is.na(first_frame)) |>
      count(angle, docked)
  ),
  tar_target(
    from_first_contact,
    interacting |>
      left_join(first_frames) |>
      filter(!is.na(first_frame), frame >= first_frame) |>
      select(-first_frame)
  ),
  tar_target(
    rolling,
    from_first_contact |>
      group_by(run, angle, frame) |>
      summarise(n_i = sum(n_pip > 0)) |>
      group_by(run, angle) |>
      arrange(run, angle, frame) |>
      mutate(n_i = zoo::rollmedian(x = n_i, k = 5, fill = NA),
             delta = c(0, diff(n_i, 1)),
             time = frame - min(frame)) |>
      ungroup() |>
      filter(!is.na(n_i), !is.na(delta)) |>
      select(-frame)
  ),
  tar_target(
    rolling_regardless_of_contact,
    interacting |>
      group_by(run, angle, frame) |>
      summarise(n_i = sum(n_pip > 0)) |>
      group_by(run, angle) |>
      arrange(run, angle, frame) |>
      mutate(n_i = zoo::rollmedian(x = n_i, k = 5, fill = NA),
             delta = c(0, diff(n_i, 1)),
             time = frame - min(frame)) |>
      ungroup() |>
      filter(!is.na(n_i), !is.na(delta)) |>
      select(-frame)
  ),
  tar_target(
    stuck,
    rolling_regardless_of_contact |>
      group_by(run, angle) |>
      summarise(contact = sum(n_i) > 0,
                final_contact = last(n_i) > 0) |>
      ungroup() |>
      mutate(
        stuck = case_when(
          contact & final_contact  ~ "retention",
          !contact                 ~ "no contact",
          contact & !final_contact ~ "no retention",
          TRUE ~ "something went wrong with my boolean logic"
        )
      ) |>
      count(stuck)
  ),
  tar_target(
    f0f1_top_interacting,
    interacting |>
      group_by(i) |>
      summarise(n_pip = mean(n_pip)) |>
      left_join(sequence) |>
      filter(n_pip > 0.1) |>
      mutate(residue = paste(res, i)) |>
      select(residue, mean_n_pip = n_pip)
  ),
  tar_target(
    f0f1_top_interacting_table,
    {
      path_f0f1_top_interacting_md <- "results/tables/f0f1-top-interacting-tbl.md"
      f0f1_top_interacting |>
        kable(format = "pipe",
              digits = 3,
              caption = "Top residues interacting with F0F1 {#tbl-f0f1-top-interacting}") |>
        write_lines(path_f0f1_top_interacting_md)
      path_f0f1_top_interacting_md
    },
    format = "file"
  ),


  #### f0f1 pulling ####
  tar_target(
    paths_f0f1_pulling_dists,
    {
      prefix <- data_path_prefix
      glue("{prefix}/f0f1-vert-pulling/conan_run{1:6}/matrices/filtered/")
    },
    format = "file"
  ),
  tar_target(
    paths_f0f1_pulling_xvg,
    {
      prefix <- data_path_prefix
      fs::dir_ls(glue("{prefix}/f0f1-vert-pulling/"), glob = "*.xvg")
    },
    format = "file"
  ),
  tar_target(
    f0f1_pulling_dists,
    paths_f0f1_pulling_dists |>
      unclass() |>
      set_names() |>
      future_map_dfr(possibly(read_pulling_dist_matrices, tibble(frame = NA)),
                     .id = "path") |>
      mutate(run = parse_number(str_extract(path, "conan_run\\d+")))
  ),
  tar_target(
    f0f1_pulling_interacting,
    f0f1_pulling_dists |>
      group_by(run, frame, i) |>
      summarise(n_pip = sum(r <= CUTOFF)) |>
      ungroup()
  ),
  tar_target(
    f0f1_pulling,
    paths_f0f1_pulling_xvg |>
      unclass() |>
      set_names(basename) |>
      map_dfr(parse_pullf_xvg, .id = "path") |>
      extract(path, c("speed", "run", "type"),
              regex = "pull_(\\d+)_?(run\\w)?_pull(\\w)") |>
      mutate(run = parse_number(run)) |>
      replace_na(list(run = 1)) |>
      pivot_wider(names_from = type, values_from = value)
  ),
  tar_target(
  f0f1_pulling_smooth,
  f0f1_pulling |>
    filter(speed == "00003") |>
    group_by(run) |>
    mutate(f = zoo::rollmean(f, 500, na.pad = TRUE),
           x = zoo::rollmean(x, 500, na.pad = TRUE)) |>
    filter(!is.na(f)) |>
    ungroup()
  ),
  tar_target(
    f0f1_pulling_peaks,
    f0f1_pulling_smooth |>
      group_by(speed, run) |>
      summarise(f = max(f, na.rm = TRUE))
  ),


#### ferm equilibrium ####
  tar_target(
    paths_ferm_distances,
    {
      prefix <- data_path_prefix
      run <- 1:6
      paths <- glue("{prefix}/tln1_ferm_memb/run_{run}/conan/matrices/filtered/")
      paths
    }
  ),
  tar_target(
    ferm_distances_per_run,
    read_ferm_distance_matrices(paths_ferm_distances),
    pattern = map(paths_ferm_distances)
  ),
  tar_target(
    ferm_interacting_per_run,
    summarize_interacting_run(ferm_distances_per_run, CUTOFF),
    pattern = map(ferm_distances_per_run)
  ),
  tar_target(
    ferm_distances,
    bind_rows(ferm_distances_per_run)
  ),
  tar_target(
    ferm_interacting,
    bind_rows(ferm_interacting_per_run)
  ),
  tar_target(
    ferm_top_interacting,
    ferm_interacting |>
      group_by(i) |>
      summarise(n_pip = mean(n_pip)) |>
      left_join(sequence) |>
      filter(n_pip > 0.1) |>
      mutate(residue = paste(res, i)) |>
      select(residue, mean_n_pip = n_pip)
  ),
  tar_target(
    ferm_top_interacting_table,
    {
      path_ferm_top_interacting_md <- "results/tables/ferm-top-interacting-tbl.md"
      ferm_top_interacting |>
        kable(format = "pipe",
              digits = 3,
              caption = "Top residues interacting with FERM {#tbl-ferm-top-interacting}") |>
        write_lines(path_ferm_top_interacting_md)
      path_ferm_top_interacting_md
    },
    format = "file"
  )
)
