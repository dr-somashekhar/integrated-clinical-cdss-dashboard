# ==============================================================================
# 🐳 DOCKER CONTAINER CONFIGURATION FOR CLINICAL CDSS ENGINE
# 
# Description: This Dockerfile establishes an isolated, highly reproducible 
# Linux environment for the R Shiny Clinical Decision Support System. 
# It ensures the engine runs identically on any enterprise cloud infrastructure 
# (AWS, Azure, GCP) or local hospital server, eliminating dependency conflicts.
# ==============================================================================

# --- 1. Define the Base Image ---
# We build upon the official "rocker/shiny" image, which contains a stable 
# version of R and a pre-configured Shiny Server running on Ubuntu Linux.
FROM rocker/shiny:4.2.1

# --- 2. Metadata & Authorship ---
# Flags the creator of this clinical pipeline for version control and audits.
LABEL maintainer="Dr. Soma Sekhar Pulamarasetti"
LABEL version="1.0"
LABEL description="Production-ready container for T2DM CDSS and Hepatic Risk Engine"

# --- 3. Install System-Level Dependencies ---
# Advanced R packages (like ggplot2 and dplyr) require underlying C++ and Linux 
# libraries to compile correctly. We chain these commands with '&&' to minimize 
# the overall size of the Docker image layer.
RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    && rm -rf /var/lib/apt/lists/*

# --- 4. Install R Language Libraries ---
# We execute a single R command to reach out to the CRAN repository and install 
# every package required by our app.R script.
RUN R -e "install.packages(c('shiny', 'shinydashboard', 'ggplot2', 'dplyr', 'corrplot', 'DT', 'tidyr'), repos='http://cran.rstudio.com/')"

# --- 5. Clean Default Server Directory ---
# The base image comes with a default "Hello World" app. We remove it to ensure 
# our clinical dashboard is the only application hosted on this container.
RUN rm -rf /srv/shiny-server/*

# --- 6. Inject the Clinical Application ---
# This copies your massive app.R file from your GitHub repository directly 
# into the Docker container's active server directory.
COPY app.R /srv/shiny-server/

# --- 7. Configure Security & Permissions ---
# Grants the internal 'shiny' user full execution rights over the application, 
# preventing permission-denied crashes during runtime.
RUN chown -R shiny:shiny /srv/shiny-server

# --- 8. Network Exposure ---
# Port 3838 is the standard port for web traffic on R Shiny servers.
EXPOSE 3838

# --- 9. Initialization Command ---
# When the container is booted up by the cloud provider, this final command 
# starts the Shiny Server, bringing the CDSS online globally.
CMD ["/usr/bin/shiny-server"]
