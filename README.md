# 🏥 Integrated Clinical Decision Support System (CDSS)
**Cardiometabolic & Hepatic Risk Prediction Dashboard for Type 2 Diabetes**

## 📖 Project Overview
This repository contains a production-grade Clinical Decision Support System (CDSS) built using **R Shiny**. The engine is designed to ingest raw patient anthropometric data, lipid panels, and hepatic transaminases to automatically compute advanced metabolic risk indices. 

Developed from clinical data methodologies exploring the association between dyslipidemia and non-alcoholic fatty liver disease (NAFLD) in Type 2 Diabetes Mellitus (T2DM), this tool bridges the gap between raw laboratory values and actionable clinical pharmacovigilance.

---

## 🧮 Core Computational Engine

The backend logic module programmatically calculates validated clinical equations to stratify patient risk in real-time.

### 1. Hepatic Steatosis Index (HSI)
A validated screening tool for detecting NAFLD/MASLD, heavily reliant on transaminase ratios. An HSI > 36 rules in hepatic steatosis with high specificity.
$$ \text{HSI} = 8 \times \left( \frac{\text{ALT}}{\text{AST}} \right) + \text{BMI} + 2 (\text{if female}) + 2 (\text{if diabetic}) $$

### 2. Atherogenic Index of Plasma (AIP)
A mathematical logarithm utilized to predict the risk of atherosclerosis and cardiovascular events, outperforming standard LDL-C tracking in patients with metabolic syndrome.
$$ \text{AIP} = \log_{10} \left( \frac{\text{TG}}{\text{HDL-C}} \right) $$

### 3. Cockcroft-Gault Creatinine Clearance (CrCl)
The foundational pharmacokinetic baseline for renal dose adjustments.
$$ \text{CrCl} = \frac{(140 - \text{Age}) \times \text{Weight (kg)}}{72 \times \text{Serum Creatinine}} \times 0.85 (\text{if female}) $$

---

## ⚠️ Pharmacovigilance & Safety Alert Layer

The dashboard integrates an automated clinical rules engine that cross-references the computed biomarkers against the patient's active medication list to flag critical interactions:

*   **Metformin & Renal Impairment:** Triggers a contraindication alert (risk of lactic acidosis) when computed CrCl drops below 30 mL/min, and a dosage warning for 30-45 mL/min.
*   **Statin Hepatotoxicity:** Screens AST/ALT values, firing critical alerts if transaminases exceed 3x the upper limit of normal (ULN) while on Atorvastatin.
*   **Geriatric Prescribing Cascades (Pharmacodynamic Antagonism):** Automatically flags concurrent prescriptions of Acetylcholinesterase Inhibitors (Donepezil) and Anticholinergics (Oxybutynin), which dynamically cancel each other's therapeutic efficacy.

---

## 📊 Population Analytics Architecture

The dashboard includes a simulated data pipeline mirroring a 170-patient prospective observational cohort (Cases vs. Controls). It utilizes `ggplot2` and `corrplot` to render:
*   Pearson Correlation Matrices mapping the mathematical relationships between LDL-C, TG, ALT, and HbA1c.
*   Linear regression scatter plots mapping dyslipidemia severity against BMI stratifications.

## 🚀 Deployment Instructions
To run this CDSS locally:
1. Clone this repository.
2. Ensure R and RStudio are installed.
3. Install dependencies: `install.packages(c("shiny", "shinydashboard", "ggplot2", "dplyr", "corrplot", "DT", "tidyr"))`
4. Run `shiny::runApp('app.R')`
