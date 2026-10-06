# =========================================================================================
# CLINICAL LOGIC: pure, UI-independent functions
#
# Everything in this file is free of Shiny state so it can be unit-tested
# (see tests/testthat/). Shiny sources every file in R/ automatically.
# =========================================================================================

# Upper limit of normal (U/L) used for the transaminase safety rule. Laboratories differ;
# adjust to the reporting laboratory's reference range if required.
ULN_TRANSAMINASE <- 40

# --- 1. Biomarker calculators ---------------------------------------------------------------

#' Body Mass Index (kg/m^2)
calc_bmi <- function(weight_kg, height_cm) {
  weight_kg / (height_cm / 100)^2
}

#' Cockcroft-Gault creatinine clearance (mL/min), using actual body weight
calc_crcl <- function(age, weight_kg, scr_mg_dl, sex) {
  crcl <- ((140 - age) * weight_kg) / (72 * scr_mg_dl)
  if (identical(sex, "Female")) crcl * 0.85 else crcl
}

#' Hepatic Steatosis Index: 8 * ALT/AST + BMI + 2 (female) + 2 (diabetes)
calc_hsi <- function(alt, ast, bmi, sex, diabetic) {
  8 * (alt / ast) + bmi + (if (identical(sex, "Female")) 2 else 0) + (if (isTRUE(diabetic)) 2 else 0)
}

#' Atherogenic Index of Plasma: log10(TG / HDL-C), both in mg/dL
calc_aip <- function(tg, hdl) {
  log10(tg / hdl)
}

#' Waist-to-height ratio
calc_whtr <- function(waist_cm, height_cm) {
  waist_cm / height_cm
}

#' Non-HDL cholesterol (mg/dL)
calc_non_hdl <- function(tc, hdl) {
  tc - hdl
}

# --- 2. Risk classification (returns a shinydashboard colour) --------------------------------

classify_bmi <- function(bmi) {
  if (bmi >= 30) "red" else if (bmi >= 25) "yellow" else "green"
}

classify_crcl <- function(crcl) {
  if (crcl < 30) "red" else if (crcl < 60) "yellow" else "green"
}

# HSI < 30 rules out and > 36 rules in NAFLD; 30-36 is indeterminate.
classify_hsi <- function(hsi) {
  if (hsi > 36) "red" else if (hsi >= 30) "yellow" else "green"
}

classify_aip <- function(aip) {
  if (aip > 0.24) "red" else if (aip > 0.11) "yellow" else "green"
}

# --- 3. Input validation ---------------------------------------------------------------------

# Plausible physiological ranges: c(min, max). Values outside them are rejected rather than
# silently producing a misleading score.
INPUT_RANGES <- list(
  age    = c(18, 110),
  weight = c(20, 400),
  height = c(100, 250),
  waist  = c(40, 250),
  scr    = c(0.1, 20),
  ast    = c(1, 5000),
  alt    = c(1, 5000),
  tc     = c(50, 1000),
  tg     = c(10, 5000),
  hdl    = c(5, 200),
  ldl    = c(10, 800)
)

INPUT_LABELS <- c(
  age = "Age", weight = "Weight", height = "Height", waist = "Waist circumference",
  scr = "Serum creatinine", ast = "AST", alt = "ALT", tc = "Total cholesterol",
  tg = "Triglycerides", hdl = "HDL cholesterol", ldl = "LDL cholesterol"
)

#' Returns a character vector of problems with `patient` (empty if the input is usable).
validate_patient <- function(patient) {
  problems <- character(0)
  for (field in names(INPUT_RANGES)) {
    value <- patient[[field]]
    rng <- INPUT_RANGES[[field]]
    label <- INPUT_LABELS[[field]]
    if (is.null(value) || length(value) != 1 || !is.numeric(value) || is.na(value)) {
      problems <- c(problems, sprintf("%s is missing or not a number.", label))
    } else if (value < rng[1] || value > rng[2]) {
      problems <- c(problems, sprintf("%s must be between %s and %s.", label, rng[1], rng[2]))
    }
  }
  problems
}

# --- 4. Master computation -------------------------------------------------------------------

#' Computes every metric from a patient list. Assumes `validate_patient()` returned nothing.
compute_metrics <- function(patient) {
  bmi <- calc_bmi(patient$weight, patient$height)
  list(
    bmi     = round(bmi, 2),
    crcl    = round(calc_crcl(patient$age, patient$weight, patient$scr, patient$sex), 2),
    hsi     = round(calc_hsi(patient$alt, patient$ast, bmi, patient$sex, patient$diabetes == "Yes"), 2),
    aip     = round(calc_aip(patient$tg, patient$hdl), 3),
    ast_alt = round(patient$ast / patient$alt, 2),
    whtr    = round(calc_whtr(patient$waist, patient$height), 2),
    non_hdl = calc_non_hdl(patient$tc, patient$hdl)
  )
}

# --- 5. Pharmacovigilance rules engine -------------------------------------------------------

#' Screens the medication list against the patient's labs and computed metrics.
#' Returns a data.frame with columns `severity` ("danger"/"warning"), `title`, `message`
#' (zero rows when nothing is flagged).
screen_medications <- function(patient, meds, metrics) {
  alerts <- list()
  add <- function(severity, title, message) {
    alerts[[length(alerts) + 1]] <<- data.frame(
      severity = severity, title = title, message = message, stringsAsFactors = FALSE
    )
  }
  has <- function(drug) drug %in% meds

  # Rule 1: Metformin + renal impairment
  if (has("Metformin") && metrics$crcl < 30) {
    add("danger", "METFORMIN CONTRAINDICATION",
        "CrCl is below 30 mL/min. High risk of lactic acidosis. Discontinue and review therapy.")
  } else if (has("Metformin") && metrics$crcl < 45) {
    add("warning", "METFORMIN WARNING",
        "CrCl is 30-45 mL/min. Do not initiate; if continuing, reassess benefit/risk and consider dose reduction (commonly a maximum of 1000 mg/day).")
  }

  # Rule 2: Statin + transaminase elevation (> 3x ULN)
  if (has("Atorvastatin") &&
      (patient$ast > 3 * ULN_TRANSAMINASE || patient$alt > 3 * ULN_TRANSAMINASE)) {
    add("danger", "STATIN HEPATOTOXICITY RISK",
        sprintf("AST or ALT exceeds 3x the upper limit of normal (%d U/L). Consider withholding the statin and evaluate hepatic function.",
                3 * ULN_TRANSAMINASE))
  }

  # Rule 3: Acetylcholinesterase inhibitor + anticholinergic
  if (has("Donepezil") && has("Oxybutynin")) {
    add("danger", "PHARMACODYNAMIC ANTAGONISM",
        "Donepezil (AChEI) combined with Oxybutynin (anticholinergic): the drugs oppose each other's cognitive and bladder effects. Review the need for both.")
  }

  # Rule 4: NSAID + antihypertensive prescribing cascade
  if (has("Ibuprofen") && has("Amlodipine")) {
    add("warning", "PRESCRIBING CASCADE RISK",
        "NSAIDs can raise blood pressure. Confirm Amlodipine was not added to treat NSAID-induced hypertension.")
  }

  if (length(alerts) == 0) {
    return(data.frame(severity = character(0), title = character(0), message = character(0),
                      stringsAsFactors = FALSE))
  }
  do.call(rbind, alerts)
}
