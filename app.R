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
# (Clinical formulas, the rules engine and the synthetic cohort live in R/ and are sourced
#  automatically by Shiny.)
# -----------------------------------------------------------------------------------------
library(shiny)
library(shinydashboard)
library(ggplot2)
library(corrplot)
library(DT)

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
      menuItem("4. Cohort Analytics (Synthetic)", tabName = "analytics", icon = icon("chart-line"))
    )
  ),
  
  # --- 2.3 Dashboard Body & Tab Architecture ---
  dashboardBody(
    tags$div(class = "callout callout-warning", style = "margin: 0 0 15px 0;",
             tags$b("Decision support only. "),
             "Outputs are screening aids for qualified clinicians and do not replace clinical judgement.",
             " Do not enter identifiable patient information."),
    tabItems(
      
      # -----------------------------------------------------------
      # TAB 1: Patient Intake (Demographics, Vitals, Labs)
      # -----------------------------------------------------------
      tabItem(tabName = "intake",
              fluidRow(
                box(title = "Demographics & Anthropometrics", status = "primary", solidHeader = TRUE, width = 4,
                    numericInput("age", "Age (years):", value = 55, min = 18, max = 110),
                    selectInput("sex", "Biological Sex:", choices = c("Male", "Female")),
                    numericInput("weight", "Weight (kg):", value = 75, min = 20, max = 400),
                    numericInput("height", "Height (cm):", value = 165, min = 100, max = 250),
                    numericInput("waist", "Waist Circumference (cm):", value = 90, min = 40, max = 250)
                ),
                box(title = "Glycemic & Renal Markers", status = "warning", solidHeader = TRUE, width = 4,
                    numericInput("fbs", "Fasting Blood Sugar (mg/dL):", value = 140, min = 20, max = 1000),
                    numericInput("hba1c", "HbA1c (%):", value = 7.5, min = 3, max = 20, step = 0.1),
                    numericInput("scr", "Serum Creatinine (mg/dL):", value = 1.1, min = 0.1, max = 20, step = 0.1),
                    selectInput("diabetes", "Known Type 2 Diabetes?", choices = c("Yes", "No"))
                ),
                box(title = "Hepatic & Lipid Panel", status = "danger", solidHeader = TRUE, width = 4,
                    numericInput("ast", "AST (U/L):", value = 40, min = 1, max = 5000),
                    numericInput("alt", "ALT (U/L):", value = 65, min = 1, max = 5000),
                    numericInput("tc", "Total Cholesterol (mg/dL):", value = 240, min = 50, max = 1000),
                    numericInput("tg", "Triglycerides (mg/dL):", value = 195, min = 10, max = 5000),
                    numericInput("hdl", "HDL Cholesterol (mg/dL):", value = 35, min = 5, max = 200),
                    numericInput("ldl", "LDL Cholesterol (mg/dL):", value = 160, min = 10, max = 800)
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
      # TAB 4: Population Analytics (Synthetic Cohort)
      # -----------------------------------------------------------
      tabItem(tabName = "analytics",
              h2("Synthetic Cohort Analysis (N = 170)"),
              fluidRow(
                box(title = "Correlation Matrix (Lipids vs Hepatic Enzymes)", status = "primary", width = 6,
                    plotOutput("corr_plot", height = "400px")),
                box(title = "Dyslipidemia by BMI Stratification", status = "warning", width = 6,
                    plotOutput("scatter_plot", height = "400px"))
              ),
              fluidRow(
                box(title = "Synthetic Patient Cohort Data (simulated - not real patients)", status = "info", width = 12,
                    DTOutput("population_table"))
              )
      )
    )
  )
)

# -----------------------------------------------------------------------------------------
# SECTION 3: SERVER LOGIC
# -----------------------------------------------------------------------------------------
server <- function(input, output, session) {

  # --- 3.1 Snapshot of inputs + computed metrics, taken only when the button is pressed ---
  # Medications and labs are captured together, so alerts can never mix a stale result with
  # edited inputs.
  results <- eventReactive(input$calc_btn, {
    patient <- list(
      age = input$age, sex = input$sex, weight = input$weight, height = input$height,
      waist = input$waist, scr = input$scr, diabetes = input$diabetes,
      ast = input$ast, alt = input$alt, tc = input$tc, tg = input$tg,
      hdl = input$hdl, ldl = input$ldl, hba1c = input$hba1c, fbs = input$fbs
    )
    problems <- validate_patient(patient)
    if (length(problems) > 0) {
      return(list(ok = FALSE, problems = problems))
    }
    metrics <- compute_metrics(patient)
    list(ok = TRUE, patient = patient, meds = input$meds, metrics = metrics,
         alerts = screen_medications(patient, input$meds, metrics))
  })

  # Stops an output with a readable message until a valid calculation exists.
  valid_results <- function() {
    res <- results()
    validate(need(res$ok, paste(c("Please correct the following inputs:", res$problems), collapse = "\n")))
    res
  }

  # --- 3.2 Dynamic ValueBox Rendering ---
  output$bmi_box <- renderValueBox({
    m <- valid_results()$metrics
    valueBox(m$bmi, "Body Mass Index (BMI)", icon = icon("weight"), color = classify_bmi(m$bmi))
  })

  output$crcl_box <- renderValueBox({
    m <- valid_results()$metrics
    valueBox(m$crcl, "CrCl (mL/min)", icon = icon("filter"), color = classify_crcl(m$crcl))
  })

  output$hsi_box <- renderValueBox({
    m <- valid_results()$metrics
    valueBox(m$hsi, "Hepatic Steatosis Index", icon = icon("procedures"), color = classify_hsi(m$hsi))
  })

  output$aip_box <- renderValueBox({
    m <- valid_results()$metrics
    valueBox(m$aip, "Atherogenic Index (AIP)", icon = icon("heartbeat"), color = classify_aip(m$aip))
  })

  # --- 3.3 Clinical Interpretation Text ---
  output$clinical_summary <- renderUI({
    res <- valid_results()
    m <- res$metrics
    p <- res$patient

    hsi_text <- if (m$hsi > 36) "suggests hepatic steatosis (NAFLD/MASLD) is likely"
                else if (m$hsi < 30) "makes hepatic steatosis unlikely"
                else "is indeterminate (30-36)"
    aip_text <- if (m$aip > 0.24) "high" else if (m$aip > 0.11) "intermediate" else "low"

    items <- list(
      sprintf("<b>Hepatic Risk:</b> HSI is %s, which %s (HSI &gt; 36 rules in, &lt; 30 rules out). AST/ALT ratio is %s.",
              m$hsi, hsi_text, m$ast_alt),
      sprintf("<b>Cardiovascular Risk:</b> AIP is %s (%s risk; &gt; 0.24 is high). Non-HDL cholesterol is %s mg/dL.",
              m$aip, aip_text, m$non_hdl),
      sprintf("<b>Renal Function:</b> Cockcroft-Gault clearance is %s mL/min.", m$crcl),
      sprintf("<b>Central Adiposity:</b> Waist-to-height ratio is %s (&gt; 0.5 indicates increased cardiometabolic risk).",
              m$whtr)
    )
    if (p$diabetes == "No" && (p$hba1c >= 6.5 || p$fbs >= 126)) {
      items <- c(items, "<b>Glycemic Note:</b> Diabetes is recorded as 'No', but HbA1c &ge; 6.5% or fasting glucose &ge; 126 mg/dL is in the diabetic range. Please verify the diagnosis.")
    }
    HTML(paste(items, collapse = "<br/><br/>"))
  })

  # --- 3.4 Pharmacovigilance Alerts ---
  output$safety_alerts <- renderUI({
    res <- valid_results()
    alerts <- res$alerts
    if (nrow(alerts) == 0) {
      return(tags$div(class = "alert alert-success",
                      "No critical drug-disease or drug-drug interactions detected based on current parameters."))
    }
    tagList(lapply(seq_len(nrow(alerts)), function(i) {
      tags$div(class = paste("alert", paste0("alert-", alerts$severity[i])),
               tags$b(paste0(alerts$title[i], ":")), " ", alerts$message[i])
    }))
  })

  # --- 3.5 Synthetic Population ---
  # Generated once per session (deterministic seed) rather than re-simulated per output.
  population <- reactive(simulate_population())

  output$corr_plot <- renderPlot({
    numeric_df <- population()[, c("BMI", "FBS", "TC", "TG", "LDL", "ALT", "AST")]
    corrplot(cor(numeric_df, use = "complete.obs"), method = "color", type = "upper",
             addCoef.col = "black", tl.col = "darkblue", tl.srt = 45,
             title = "Pearson Correlation of Metabolic Parameters", mar = c(0, 0, 1, 0))
  })

  output$scatter_plot <- renderPlot({
    ggplot(population(), aes(x = BMI, y = LDL, color = Group)) +
      geom_point(alpha = 0.6, size = 3) +
      geom_smooth(method = "lm", formula = y ~ x, se = TRUE) +
      scale_color_manual(values = c("Cases" = "red", "Controls" = "green4")) +
      labs(title = "Linear Regression: BMI vs. LDL Cholesterol (synthetic data)",
           x = "Body Mass Index (kg/m\u00b2)", y = "LDL-C (mg/dL)") +
      theme_minimal() +
      theme(text = element_text(size = 14))
  })

  output$population_table <- renderDT({
    datatable(population(), rownames = FALSE, options = list(pageLength = 5, scrollX = TRUE))
  })
}

# -----------------------------------------------------------------------------------------
# SECTION 4: APPLICATION EXECUTION
# -----------------------------------------------------------------------------------------
shinyApp(ui = ui, server = server)
