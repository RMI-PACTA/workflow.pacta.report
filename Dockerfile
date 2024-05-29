FROM docker.io/rocker/r-ver:4.3.1 AS base

# set Docker image labels
LABEL org.opencontainers.image.source=https://github.com/RMI-PACTA/workflow.pacta.report
LABEL org.opencontainers.image.description="Docker image to create PACTA reports and executive summaries"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="workflow.pacta.report"
LABEL org.opencontainers.image.vendor="RMI"
LABEL org.opencontainers.image.base.name="ghcr.io/rmi-pacta/workflow.pacta:main"
LABEL org.opencontainers.image.authors="Alex Axthelm"

# install system dependencies
USER root
RUN apt-get update \
    && DEBIAN_FRONTEND="noninteractive" \
    apt-get install -y --no-install-recommends \
      libicu-dev=70.* \
      libpng-dev=1.6.* \
      libxt6=1:1.2.* \
      pandoc=2.9.* \
    && chmod -R a+rwX /root \
    && rm -rf /var/lib/apt/lists/*

# set frozen CRAN repo and RProfile.site
# This block makes use of the builtin ARG $TARGETPLATFORM (See:
# https://www.docker.com/blog/faster-multi-platform-builds-dockerfile-cross-compilation-guide/
# ) to pick the correct CRAN-like repo, which will let us target binaries fo
# supported platforms
ARG TARGETPLATFORM
RUN PACKAGE_PIN_DATE="2024-04-05" && \
  echo "TARGETPLATFORM: $TARGETPLATFORM" && \
  if [ "$TARGETPLATFORM" = "linux/amd64" ] && grep -q -e "Jammy Jellyfish" "/etc/os-release" ; then \
    CRAN_LIKE_URL="https://packagemanager.posit.co/cran/__linux__/jammy/$PACKAGE_PIN_DATE"; \
  else \
    CRAN_LIKE_URL="https://packagemanager.posit.co/cran/$PACKAGE_PIN_DATE"; \
  fi && \
  echo "CRAN_LIKE_URL: $CRAN_LIKE_URL" && \
  printf "options(\n \
    repos = c(CRAN = '%s'),\n \
    pak.no_extra_messages = TRUE,\n \
    pkg.sysreqs = FALSE,\n \
    pkg.sysreqs_db_update = FALSE,\n \
    pkg.sysreqs_update = FALSE\n \
  )\n" \
  "$CRAN_LIKE_URL" \
  > "${R_HOME}/etc/Rprofile.site" \
  && Rscript -e "install.packages('pak', repos = sprintf('https://r-lib.github.io/p/pak/stable/%s/%s/%s', .Platform[['pkgType']], R.Version()[['os']], R.Version()[['arch']]))"

# Create and use non-root user
# -m creates a home directory,
# -G adds user to staff group allowing R package installation.
RUN useradd \
      -m \
      -G staff \
      workflow-pacta-report
USER workflow-pacta-report
WORKDIR /home/workflow-pacta-report

# copy in everything from this repo
COPY DESCRIPTION /workflow.pacta.report/DESCRIPTION

# Rprofile, including CRAN-like repos are inhertied from base image
# install pak, find dependencises from DESCRIPTION, and install them.
RUN Rscript -e "pak::local_install_deps(root = '/workflow.pacta.report')"

FROM base AS install-pacta

COPY . /workflow.pacta.report/

RUN Rscript -e "pak::local_install(root = '/workflow.pacta.report')"

# set default run behavior
ENTRYPOINT ["/workflow.pacta.report/run-pacta.sh"]
