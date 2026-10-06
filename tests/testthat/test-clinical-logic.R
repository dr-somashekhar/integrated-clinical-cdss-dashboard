source(file.path("..", "..", "R", "clinical_logic.R"))
source(file.path("..", "..", "R", "simulation.R"))

patient <- function(...) {
  base <- list(age = 55, sex = "Male", weight = 75, height = 165, waist = 90, scr = 1.1,
               diabetes = "Yes", ast = 40, alt = 65, tc = 240, tg = 195, hdl = 35, ldl = 160)
  modifyList(base, list(...))
}

test_that("calculators match hand-computed values", {
  expect_equal(calc_bmi(75, 165), 75 / 1.65^2)
  expect_equal(calc_crcl(60, 80, 1, "Male"), (80 * 80) / 72)
  expect_equal(calc_crcl(60, 80, 1, "Female"), (80 * 80) / 72 * 0.85)
  expect_equal(calc_hsi(60, 30, 25, "Male", FALSE), 8 * 2 + 25)
  expect_equal(calc_hsi(60, 30, 25, "Female", TRUE), 8 * 2 + 25 + 4)
  expect_equal(calc_aip(100, 100), 0)
  expect_equal(calc_aip(1000, 100), 1)
})

test_that("classification thresholds", {
  expect_equal(classify_hsi(36.5), "red")
  expect_equal(classify_hsi(33), "yellow")
  expect_equal(classify_hsi(29), "green")
  expect_equal(classify_crcl(29), "red")
  expect_equal(classify_crcl(45), "yellow")
  expect_equal(classify_aip(0.3), "red")
})

test_that("validation rejects unusable input", {
  expect_length(validate_patient(patient()), 0)
  expect_match(validate_patient(patient(ast = 0)), "AST")
  expect_match(validate_patient(patient(hdl = NA_real_)), "HDL")
  expect_match(validate_patient(patient(scr = 0)), "creatinine")
  expect_length(validate_patient(patient(height = NULL)), 1)
})

test_that("metformin rule is tiered by CrCl", {
  m <- function(crcl) list(crcl = crcl)
  expect_equal(screen_medications(patient(), "Metformin", m(25))$severity, "danger")
  expect_equal(screen_medications(patient(), "Metformin", m(40))$severity, "warning")
  expect_equal(nrow(screen_medications(patient(), "Metformin", m(60))), 0)
  expect_equal(nrow(screen_medications(patient(), character(0), m(10))), 0)
})

test_that("statin rule fires above 3x ULN only", {
  m <- list(crcl = 90)
  expect_equal(nrow(screen_medications(patient(alt = 120), "Atorvastatin", m)), 0)
  expect_equal(screen_medications(patient(alt = 121), "Atorvastatin", m)$severity, "danger")
  expect_equal(nrow(screen_medications(patient(alt = 500), "Metformin", m)), 0)
})

test_that("drug-drug rules fire", {
  m <- list(crcl = 90)
  expect_equal(nrow(screen_medications(patient(), c("Donepezil", "Oxybutynin"), m)), 1)
  expect_equal(nrow(screen_medications(patient(), "Donepezil", m)), 0)
  expect_equal(screen_medications(patient(), c("Ibuprofen", "Amlodipine"), m)$severity, "warning")
})

test_that("compute_metrics returns rounded values", {
  mt <- compute_metrics(patient())
  expect_equal(mt$bmi, 27.55)
  expect_equal(mt$non_hdl, 205)
  expect_equal(mt$ast_alt, round(40 / 65, 2))
})

test_that("simulation is deterministic, sized correctly and in range", {
  a <- simulate_population()
  expect_equal(nrow(a), 170)
  expect_identical(a, simulate_population())
  expect_true(all(a$ALT >= 5 & a$AST >= 5 & a$BMI >= 15 & a$Age >= 18))
  set.seed(1); x <- runif(1); set.seed(1); simulate_population(); expect_equal(runif(1), x)
})
