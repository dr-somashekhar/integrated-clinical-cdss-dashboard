# ==============================================================================
# Docker image for the Integrated Clinical CDSS (R Shiny)
#
# Build:  docker build -t clinical-cdss .
# Run:    docker run --rm -p 3838:3838 clinical-cdss
# Open:   http://localhost:3838/
# ==============================================================================

# rocker/shiny pins the R version and a dated CRAN snapshot, so package versions are
# reproducible for a given tag.
FROM rocker/shiny:4.2.1

LABEL maintainer="Dr. Soma Sekhar Pulamarasetti" \
      version="1.1" \
      description="R Shiny Clinical Decision Support System: T2DM cardiometabolic and hepatic risk engine"

# System libraries needed to compile/run the R packages (ggplot2, DT, ...).
RUN apt-get update && apt-get install -y --no-install-recommends \
        libcurl4-gnutls-dev \
        libcairo2-dev \
        libxt-dev \
        libssl-dev \
        libssh2-1-dev \
    && rm -rf /var/lib/apt/lists/*

# Uses the image's default (snapshot) CRAN repository. Keep in sync with DESCRIPTION.
RUN R -q -e "install.packages(c('shinydashboard', 'ggplot2', 'corrplot', 'DT'))" \
    && R -q -e "stopifnot(all(c('shiny','shinydashboard','ggplot2','corrplot','DT') %in% rownames(installed.packages())))"

# Replace the default demo apps with this application (app.R plus its R/ modules).
RUN rm -rf /srv/shiny-server/*
COPY app.R /srv/shiny-server/app.R
COPY R/ /srv/shiny-server/R/
RUN chown -R shiny:shiny /srv/shiny-server

EXPOSE 3838

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fsS http://localhost:3838/ >/dev/null || exit 1

# Shiny Server drops privileges to the unprivileged 'shiny' user for the app processes.
CMD ["/usr/bin/shiny-server"]
