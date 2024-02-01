# using rocker r-vers as a base with R 4.3.1
# https://hub.docker.com/r/rocker/r-ver
# https://rocker-project.org/images/versioned/r-ver.html
#
# sets CRAN repo to use Posit Package Manager to freeze R package versions to
# those available on 2023-10-30
# https://packagemanager.posit.co/client/#/repos/2/overview
# https://packagemanager.posit.co/cran/__linux__/jammy/2023-10-30

# set proper base image
ARG R_VERS="4.3.1"
FROM ghcr.io/rmi-pacta/workflow.pacta:main AS base

# set Docker image labels
LABEL org.opencontainers.image.source=https://github.com/RMI-PACTA/workflow.pacta.report
LABEL org.opencontainers.image.description="Docker image to run PACTA"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title=""
LABEL org.opencontainers.image.revision=""
LABEL org.opencontainers.image.version=""
LABEL org.opencontainers.image.vendor=""
LABEL org.opencontainers.image.base.name=""
LABEL org.opencontainers.image.ref.name=""
LABEL org.opencontainers.image.authors=""

# set apt-get to noninteractive mode
ARG DEBIAN_FRONTEND="noninteractive"
ARG DEBCONF_NOWARNINGS="yes"

# install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      libpng-dev=1.6.* \
      libxt6=1:1.2.* \
      pandoc=2.9.* \
    && chmod -R a+rwX /root \
    && rm -rf /var/lib/apt/lists/*

# set frozen CRAN repo
ARG CRAN_REPO="https://packagemanager.posit.co/cran/__linux__/jammy/2023-10-30"
RUN echo "options(repos = c(CRAN = '$CRAN_REPO'), pkg.sysreqs = FALSE)" >> "${R_HOME}/etc/Rprofile.site" \
      # install packages for dependency resolution and installation
      && Rscript -e "install.packages('pak'); pak::pkg_install('renv')"

FROM base AS install-pacta

# copy in everything from this repo
COPY DESCRIPTION /DESCRIPTION

# PACTA R package tags
ARG report_tag="/tree/main"
ARG summary_tag="/tree/main"
ARG utils_tag="/tree/main"

ARG report_url="https://github.com/rmi-pacta/pacta.portfolio.report"
ARG summary_url="https://github.com/rmi-pacta/pacta.executive.summary"
ARG utils_url="https://github.com/rmi-pacta/pacta.portfolio.utils"

# install R package dependencies
RUN Rscript -e "\
  gh_pkgs <- \
    c( \
      paste0('$report_url', '$report_tag'), \
      paste0('$summary_url', '$summary_tag'), \
      paste0('$utils_url', '$utils_tag') \
    ); \
  workflow_pkgs <- renv::dependencies('DESCRIPTION')[['Package']]; \
  workflow_pkgs <- grep('^pacta[.]', workflow_pkgs, value = TRUE, invert = TRUE); \
  pak::pak(c(gh_pkgs, workflow_pkgs)); \
  "

COPY . /

# set default run behavior
ENTRYPOINT ["/run-pacta.sh"]
CMD ["input_dir/default_config.json"]
