#  Integrated Clinical Decision Support System (CDSS)
**Cardiometabolic & Hepatic Risk Prediction Dashboard for Type 2 Diabetes**

##  Project Overview
This repository contains a production-grade Clinical Decision Support System (CDSS) built using **R Shiny**. The engine is designed to ingest raw patient anthropometric data, lipid panels, and hepatic transaminases to automatically compute advanced metabolic risk indices. 

Developed from clinical data methodologies exploring the association between dyslipidemia and non-alcoholic fatty liver disease (NAFLD) in Type 2 Diabetes Mellitus (T2DM), this tool bridges the gap between raw laboratory values and actionable clinical pharmacovigilance.

> **Disclaimer:** this is a research/educational decision-support prototype. It is not a certified medical device, has not been clinically validated for patient care, and must not replace clinical judgement. Never enter identifiable patient data. All cohort analytics use **synthetic** data.

---

##  Core Computational Engine

The backend logic module programmatically calculates validated clinical equations to stratify patient risk in real-time.

### 1. Hepatic Steatosis Index (HSI)
A validated screening tool for detecting NAFLD/MASLD, heavily reliant on transaminase ratios. An HSI > 36 rules in hepatic steatosis with high specificity; HSI < 30 rules it out; 30-36 is indeterminate.
$$ \text{HSI} = 8 \times \left( \frac{\text{ALT}}{\text{AST}} \right) + \text{BMI} + 2 (\text{if female}) + 2 (\text{if diabetic}) $$

### 2. Atherogenic Index of Plasma (AIP)
A mathematical logarithm utilized to predict the risk of atherosclerosis and cardiovascular events, outperforming standard LDL-C tracking in patients with metabolic syndrome.
$$ \text{AIP} = \log_{10} \left( \frac{\text{TG}}{\text{HDL-C}} \right) $$

### 3. Cockcroft-Gault Creatinine Clearance (CrCl)
The foundational pharmacokinetic baseline for renal dose adjustments.
$$ \text{CrCl} = \frac{(140 - \text{Age}) \times \text{Weight (kg)}}{72 \times \text{Serum Creatinine}} \times 0.85 (\text{if female}) $$

---

##  Pharmacovigilance & Safety Alert Layer

The dashboard integrates an automated clinical rules engine that cross-references the computed biomarkers against the patient's active medication list to flag critical interactions:

*   **Metformin & Renal Impairment:** Triggers a contraindication alert (risk of lactic acidosis) when computed CrCl drops below 30 mL/min, and an initiation/dose-review warning for 30-45 mL/min.
*   **Statin Hepatotoxicity:** Screens AST/ALT values, firing critical alerts if AST or ALT exceed 3x the upper limit of normal (ULN, 40 U/L by default) while on Atorvastatin.
*   **Geriatric Prescribing Cascades (Pharmacodynamic Antagonism):** Automatically flags concurrent prescriptions of Acetylcholinesterase Inhibitors (Donepezil) and Anticholinergics (Oxybutynin), which oppose each other's therapeutic effects.
*   **NSAID / Amlodipine Prescribing Cascade:** Warns when Ibuprofen and Amlodipine are co-prescribed, as the antihypertensive may be treating NSAID-induced hypertension.

Inputs are range-checked before any calculation (zero AST, HDL or creatinine are rejected rather than producing infinite scores), and results are snapshotted when **Run Clinical Computation Engine** is pressed so alerts always match the displayed values.

---

## Synthetic Cohort Analytics

The dashboard includes a deterministic simulated cohort (95 cases, 75 controls; N = 170) with summary statistics modelled on a prospective observational study. It uses `ggplot2` and `corrplot` to render:
*   A Pearson correlation matrix of BMI, FBS, TC, TG, LDL-C, ALT and AST.
*   Linear regression scatter plots of LDL-C against BMI for cases vs. controls.

## Project Structure

```
app.R                     Shiny UI and server wiring
R/clinical_logic.R        Calculators, validation and medication rules engine (pure functions)
R/simulation.R            Synthetic cohort generator
tests/testthat/           Unit tests for the clinical logic
Dockerfile                Container image (Shiny Server)
.github/workflows/ci.yml  Runs the tests on every push / PR
```

## Running Locally
1. Clone this repository.
2. Install R (>= 4.0) and the dependencies: `install.packages(c("shiny", "shinydashboard", "ggplot2", "corrplot", "DT"))`
3. Run `shiny::runApp()` from the repository root.

## Running with Docker
```bash
docker build -t clinical-cdss .
docker run --rm -p 3838:3838 clinical-cdss   # then open http://localhost:3838/
```

## Testing
```bash
Rscript -e 'install.packages("testthat")'
Rscript tests/testthat.R
```
