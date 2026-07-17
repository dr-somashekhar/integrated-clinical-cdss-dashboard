# =========================================================================================
# 🏥 INTEGRATED CLINICAL DECISION SUPPORT SYSTEM (CDSS)
# 🧬 Cardiometabolic & Hepatic Risk Prediction Dashboard
# 
# Description: Advanced R Shiny web application designed for real-time patient 
# risk stratification, incorporating Hepatic Steatosis Index (HSI), Atherogenic 
# Index of Plasma (AIP), and automated pharmacovigilance screening for Type 2 Diabetes.
# =========================================================================================

# -----------------------------------------------------------------------------------------
# SECTION 1: LIBRARY INITIALIZATION & DEPENDENCIES
# -----------------------------------------------------------------------------------------
library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(corrplot)
library(DT)
library(tidyr)

# -----------------------------------------------------------------------------------------
# SECTION 2: USER INTERFACE (UI) ARCHITECTURE
# -----------------------------------------------------------------------------------------
ui <- dashboardPage(
  skin = "blue",
  
  # --- 2.1 Dashboard Header ---
  dashboardHeader(title = "Clinical CDSS Engine", titleWidth = 300),
  
  # --- 2.2 Dashboard Sidebar Navigation ---
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      menuItem("1. Patient Intake & Vitals", tabName = "intake", icon = icon("user-md")),
      menuItem("2. Biomarker Risk Engine", tabName = "biomarkers", icon = icon("tint")),
      menuItem("3. Pharmacovigilance Alerts", tabName = "safety", icon = icon("exclamation-triangle")),
      menuItem("4. Population Analytics", tabName = "analytics", icon = icon("chart-line"))
    )
  ),
  
  # --- 2.3 Dashboard Body & Tab Architecture ---
  dashboardBody(
    tabItems(
      
      # -----------------------------------------------------------
      # TAB 1: Patient Intake (Demographics, Vitals, Labs)
      # -----------------------------------------------------------
      tabItem(tabName = "intake",
              fluidRow(
                box(title = "Demographics & Anthropometrics", status = "primary", solidHeader = TRUE, width = 4,
                    numericInput("age", "Age (years):", value = 55, min = 18, max = 100),
                    selectInput("sex", "Biological Sex:", choices = c("Male", "Female")),
                    numericInput("weight", "Weight (kg):", value = 75, min = 30, max = 200),
                    numericInput("height", "Height (cm):", value = 165, min = 100, max = 250),
                    numericInput("waist", "Waist Circumference (cm):", value = 90, min = 50, max = 150)
                ),
                box(title = "Glycemic & Renal Markers", status = "warning", solidHeader = TRUE, width = 4,
                    numericInput("fbs", "Fasting Blood Sugar (mg/dL):", value = 140),
                    numericInput("ppbs", "Post-Prandial Sugar (mg/dL):", value = 210),
                    numericInput("hba1c", "HbA1c (%):", value = 7.5, step = 0.1),
                    numericInput("scr", "Serum Creatinine (mg/dL):", value = 1.1, step = 0.1),
                    selectInput("diabetes", "Known Type 2 Diabetes?", choices = c("Yes", "No"))
                ),
                box(title = "Hepatic & Lipid Panel", status = "danger", solidHeader = TRUE, width = 4,
                    numericInput("ast", "AST (U/L):", value = 40),
                    numericInput("alt", "ALT (U/L):", value = 65),
                    numericInput("tc", "Total Cholesterol (mg/dL):", value = 240),
                    numericInput("tg", "Triglycerides (mg/dL):", value = 195),
                    numericInput("hdl", "HDL Cholesterol (mg/dL):", value = 35),
                    numericInput("ldl", "LDL Cholesterol (mg/dL):", value = 160)
                )
              ),
              fluidRow(
                box(title = "Current High-Alert Medications", status = "info", solidHeader = TRUE, width = 12,
                    checkboxGroupInput("meds", "Select Active Prescriptions:",
                                       choices = c("Metformin", "Atorvastatin", "Ibuprofen", 
                                                   "Donepezil", "Oxybutynin", "Amlodipine"),
                                       inline = TRUE),
                    actionButton("calc_btn", "Run Clinical Computation Engine", class = "btn-lg btn-success", icon = icon("cogs"))
                )
              )
      ),
      
      # -----------------------------------------------------------
      # TAB 2: Biomarker Risk Engine (Calculated Indices)
      # -----------------------------------------------------------
      tabItem(tabName = "biomarkers",
              h2("Advanced Predictive Clinical Biomarkers"),
              fluidRow(
                valueBoxOutput("bmi_box", width = 3),
                valueBoxOutput("crcl_box", width = 3),
                valueBoxOutput("hsi_box", width = 3),
                valueBoxOutput("aip_box", width = 3)
              ),
              fluidRow(
                box(title = "Clinical Interpretation", status = "primary", width = 12,
                    htmlOutput("clinical_summary"))
              )
      ),
      
      # -----------------------------------------------------------
      # TAB 3: Pharmacovigilance & Safety Alerts
      # -----------------------------------------------------------
      tabItem(tabName = "safety",
              h2("Automated Medication Safety Screening"),
              fluidRow(
                box(title = "Active Clinical Alerts", status = "danger", solidHeader = TRUE, width = 12,
                    uiOutput("safety_alerts"))
              )
      ),
      
      # -----------------------------------------------------------
      # TAB 4: Population Analytics (Thesis Data Simulation)
      # -----------------------------------------------------------
      tabItem(tabName = "analytics",
              h2("Population Cohort Analysis (N = 170)"),
              fluidRow(
                box(title = "Correlation Matrix (Lipids vs Hepatic Enzymes)", status = "primary", width = 6,
                    plotOutput("corr_plot", height = "400px")),
                box(title = "Dyslipidemia by BMI Stratification", status = "warning", width = 6,
                    plotOutput("scatter_plot", height = "400px"))
              ),
              fluidRow(
                box(title = "Simulated Patient Cohort Data", status = "info", width = 12,
                    dataTableOutput("population_table"))
              )
      )
    )
  )
)

# -----------------------------------------------------------------------------------------
# SECTION 3: SERVER LOGIC & COMPUTATIONAL ENGINE
# -----------------------------------------------------------------------------------------
server <- function(input, output, session) {
  
  # --- 3.1 Reactive Data Object for Computed Metrics ---
  patient_data <- reactiveValues(
    bmi = NULL, crcl = NULL, hsi = NULL, aip = NULL, ast_alt_ratio = NULL
  )
  
  # --- 3.2 Master Computation Event ---
  observeEvent(input$calc_btn, {
    # 1. Calculate BMI
    height_m <- input$height / 100
    patient_data$bmi <- round(input$weight / (height_m^2), 2)
    
    # 2. Calculate Cockcroft-Gault CrCl
    base_crcl <- ((140 - input$age) * input$weight) / (72 * input$scr)
    patient_data$crcl <- ifelse(input$sex == "Female", round(base_crcl * 0.85, 2), round(base_crcl, 2))
    
    # 3. Calculate Hepatic Steatosis Index (HSI)
    # Formula: 8 * (ALT/AST ratio) + BMI + (+2 if diabetes) + (+2 if female)
    ratio <- input$alt / input$ast
    patient_data$ast_alt_ratio <- round(1 / ratio, 2) # Storing AST/ALT for display
    
    hsi_base <- 8 * ratio + patient_data$bmi
    hsi_diabetes <- ifelse(input$diabetes == "Yes", 2, 0)
    hsi_sex <- ifelse(input$sex == "Female", 2, 0)
    patient_data$hsi <- round(hsi_base + hsi_diabetes + hsi_sex, 2)
    
    # 4. Calculate Atherogenic Index of Plasma (AIP)
    # Formula: Log10(TG / HDL)
    patient_data$aip <- round(log10(input$tg / input$hdl), 3)
  })
  
  # --- 3.3 Dynamic ValueBox Rendering ---
  output$bmi_box <- renderValueBox({
    req(patient_data$bmi)
    status_col <- ifelse(patient_data$bmi >= 30, "red", ifelse(patient_data$bmi >= 25, "yellow", "green"))
    valueBox(patient_data$bmi, "Body Mass Index (BMI)", icon = icon("weight"), color = status_col)
  })
  
  output$crcl_box <- renderValueBox({
    req(patient_data$crcl)
    status_col <- ifelse(patient_data$crcl < 30, "red", ifelse(patient_data$crcl < 60, "yellow", "green"))
    valueBox(patient_data$crcl, "CrCl (mL/min)", icon = icon("kidneys", lib="font-awesome"), color = status_col)
  })
  
  output$hsi_box <- renderValueBox({
    req(patient_data$hsi)
    status_col <- ifelse(patient_data$hsi > 36, "red", "green")
    valueBox(patient_data$hsi, "Hepatic Steatosis Index", icon = icon("procedures"), color = status_col)
  })
  
  output$aip_box <- renderValueBox({
    req(patient_data$aip)
    status_col <- ifelse(patient_data$aip > 0.24, "red", ifelse(patient_data$aip > 0.11, "yellow", "green"))
    valueBox(patient_data$aip, "Atherogenic Index (AIP)", icon = icon("heartbeat"), color = status_col)
  })
  
  # --- 3.4 Clinical Interpretation Text ---
  output$clinical_summary <- renderUI({
    req(patient_data$hsi)
    str1 <- paste("<b>Hepatic Risk:</b> An HSI > 36 highly indicates the presence of Non-Alcoholic Fatty Liver Disease (NAFLD). Patient HSI is", patient_data$hsi)
    str2 <- paste("<b>Cardiovascular Risk:</b> An AIP > 0.24 indicates high risk for atherosclerosis. Patient AIP is", patient_data$aip)
    str3 <- paste("<b>Renal Function:</b> Calculated Cockcroft-Gault clearance is", patient_data$crcl, "mL/min.")
    HTML(paste(str1, str2, str3, sep = "<br/><br/>"))
  })
  
  # --- 3.5 Automated Pharmacovigilance Rules Engine ---
  output$safety_alerts <- renderUI({
    req(input$calc_btn)
    alerts <- c()
    
    meds <- input$meds
    
    # Rule 1: Metformin + Renal Impairment
    if ("Metformin" %in% meds && patient_data$crcl < 30) {
      alerts <- c(alerts, "<div class='alert alert-danger'><b>❌ METFORMIN CONTRAINDICATION:</b> CrCl is below 30 mL/min. High risk of lactic acidosis. Discontinue immediately.</div>")
    } else if ("Metformin" %in% meds && patient_data$crcl < 45) {
      alerts <- c(alerts, "<div class='alert alert-warning'><b>⚠️ METFORMIN WARNING:</b> CrCl is 30-45 mL/min. Max dose is 1000 mg/day. Review required.</div>")
    }
    
    # Rule 2: Statins + Hepatic Transaminase Elevation
    if ("Atorvastatin" %in% meds && (input$ast > 120 || input$alt > 120)) {
      alerts <- c(alerts, "<div class='alert alert-danger'><b>❌ STATIN HEPATOTOXICITY RISK:</b> Transaminases are >3x Upper Limit of Normal. Withhold statin and evaluate hepatic architecture.</div>")
    }
    
    # Rule 3: Geriatric Prescribing Cascades (Donepezil + Oxybutynin)
    if ("Donepezil" %in% meds && "Oxybutynin" %in% meds) {
      alerts <- c(alerts, "<div class='alert alert-danger'><b>❌ PHARMACODYNAMIC ANTAGONISM:</b> Donepezil (AChEI) combined with Oxybutynin (Anticholinergic). Drugs directly cancel out cognitive and bladder benefits.</div>")
    }
    
    # Rule 4: NSAID + Amlodipine Cascade Risk
    if ("Ibuprofen" %in% meds && "Amlodipine" %in% meds) {
      alerts <- c(alerts, "<div class='alert alert-warning'><b>⚠️ PRESCRIBING CASCADE RISK:</b> NSAIDs can elevate blood pressure. Ensure Amlodipine was not added to treat NSAID-induced hypertension.</div>")
    }
    
    if (length(alerts) == 0) {
      HTML("<div class='alert alert-success'>✅ No critical drug-disease or drug-drug interactions detected based on current parameters.</div>")
    } else {
      HTML(paste(alerts, collapse = ""))
    }
  })
  
  # --- 3.6 Advanced Population Simulation (Based on N=170 Thesis Data) ---
  simulate_population <- reactive({
    set.seed(123)
    # Simulating 95 Cases (Elevated Lipids) and 75 Controls (Normal)
    n_cases <- 95
    n_controls <- 75
    
    cases <- data.frame(
      Group = "Cases",
      Age = round(rnorm(n_cases, 55, 10)),
      BMI = round(rnorm(n_cases, 30.5, 4.9), 1),
      FBS = round(rnorm(n_cases, 217.8, 41.8)),
      TC = round(rnorm(n_cases, 264, 28.4)),
      TG = round(rnorm(n_cases, 195.2, 40.6)),
      LDL = round(rnorm(n_cases, 168.5, 29.3)),
      ALT = round(rnorm(n_cases, 66.0, 41.0)),
      AST = round(rnorm(n_cases, 40.1, 25.1))
    )
    
    controls <- data.frame(
      Group = "Controls",
      Age = round(rnorm(n_controls, 45, 10)),
      BMI = round(rnorm(n_controls, 24.5, 2.2), 1),
      FBS = round(rnorm(n_controls, 185.3, 28.5)),
      TC = round(rnorm(n_controls, 176.6, 23.8)),
      TG = round(rnorm(n_controls, 151.0, 37.0)),
      LDL = round(rnorm(n_controls, 103.9, 22.3)),
      ALT = round(rnorm(n_controls, 25.1, 26.9)),
      AST = round(rnorm(n_controls, 18.8, 14.9))
    )
    
    bind_rows(cases, controls) %>% filter(Age > 18, BMI > 15)
  })
  
  # --- 3.7 Visualizations ---
  output$corr_plot <- renderPlot({
    df <- simulate_population()
    # Select continuous variables for correlation
    numeric_df <- df %>% select(BMI, FBS, TC, TG, LDL, ALT, AST)
    corr_matrix <- cor(numeric_df, use = "complete.obs")
    corrplot(corr_matrix, method = "color", type = "upper", 
             addCoef.col = "black", tl.col = "darkblue", tl.srt = 45,
             title = "Pearson Correlation of Metabolic Parameters", mar=c(0,0,1,0))
  })
  
  output$scatter_plot <- renderPlot({
    df <- simulate_population()
    ggplot(df, aes(x = BMI, y = LDL, color = Group)) +
      geom_point(alpha = 0.6, size = 3) +
      geom_smooth(method = "lm", se = TRUE) +
      scale_color_manual(values = c("Cases" = "red", "Controls" = "green4")) +
      labs(title = "Linear Regression: BMI vs. LDL Cholesterol",
           x = "Body Mass Index (kg/m²)", y = "LDL-C (mg/dL)") +
      theme_minimal() +
      theme(text = element_text(size = 14))
  })
  
  output$population_table <- renderDataTable({
    datatable(simulate_population(), options = list(pageLength = 5, scrollX = TRUE))
  })
  
}

# -----------------------------------------------------------------------------------------
# SECTION 4: APPLICATION EXECUTION
# -----------------------------------------------------------------------------------------
shinyApp(ui = ui, server = server)
