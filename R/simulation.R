# =========================================================================================
# SYNTHETIC COHORT: 170 simulated patients (95 cases, 75 controls)
#
# Parameters are illustrative, loosely modelled on summary statistics from a prospective
# observational study. The records are SYNTHETIC - no real patient data is used.
# =========================================================================================

simulate_population <- function(n_cases = 95, n_controls = 75, seed = 123) {
  # Seed locally and restore the caller's RNG state so the app does not disturb global state.
  if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
    old_seed <- get(".Random.seed", envir = globalenv())
    on.exit(assign(".Random.seed", old_seed, envir = globalenv()), add = TRUE)
  }
  set.seed(seed)

  # Normal draws can fall outside the physiological range; clamp instead of dropping rows
  # so the cohort size is exactly n_cases + n_controls.
  draw <- function(n, mean, sd, lower, upper = Inf) {
    pmin(pmax(rnorm(n, mean, sd), lower), upper)
  }

  make_group <- function(group, n, p) {
    data.frame(
      Group = group,
      Age = round(draw(n, p$age[1], p$age[2], 18, 100)),
      BMI = round(draw(n, p$bmi[1], p$bmi[2], 15), 1),
      FBS = round(draw(n, p$fbs[1], p$fbs[2], 60)),
      TC  = round(draw(n, p$tc[1],  p$tc[2],  80)),
      TG  = round(draw(n, p$tg[1],  p$tg[2],  30)),
      LDL = round(draw(n, p$ldl[1], p$ldl[2], 30)),
      ALT = round(draw(n, p$alt[1], p$alt[2], 5)),
      AST = round(draw(n, p$ast[1], p$ast[2], 5)),
      stringsAsFactors = FALSE
    )
  }

  cases <- make_group("Cases", n_cases, list(
    age = c(55, 10), bmi = c(30.5, 4.9), fbs = c(217.8, 41.8), tc = c(264, 28.4),
    tg = c(195.2, 40.6), ldl = c(168.5, 29.3), alt = c(66.0, 41.0), ast = c(40.1, 25.1)
  ))
  controls <- make_group("Controls", n_controls, list(
    age = c(45, 10), bmi = c(24.5, 2.2), fbs = c(185.3, 28.5), tc = c(176.6, 23.8),
    tg = c(151.0, 37.0), ldl = c(103.9, 22.3), alt = c(25.1, 26.9), ast = c(18.8, 14.9)
  ))

  rbind(cases, controls)
}
