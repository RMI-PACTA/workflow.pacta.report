FROM ghcr.io/rmi-pacta/workflow.pacta:pr-71 AS base

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
      libpng-dev=1.6.* \
      libxt6=1:1.2.* \
      pandoc=2.9.* \
    && chmod -R a+rwX /root \
    && rm -rf /var/lib/apt/lists/*

# copy in everything from this repo
COPY DESCRIPTION /workflow.pacta.report/DESCRIPTION

# Rprofile, including CRAN-like repos are inhertied from base image
# install pak, find dependencises from DESCRIPTION, and install them.
RUN Rscript -e "\
    install.packages('pak'); \
    deps <- pak::local_deps(root = '/workflow.pacta.report'); \
    pkg_deps <- deps[!deps[['direct']], 'ref']; \
    print(pkg_deps); \
    pak::pak(pkg_deps); \
    "

# Create and use non-root user
# -m creates a home directory,
# -G adds user to staff group allowing R package installation.
RUN useradd \
      -m \
      -G staff \
      workflow-pacta-report
USER workflow-pacta-report
WORKDIR /home/workflow-pacta-report

FROM base AS install-pacta

COPY . /workflow.pacta.report/

RUN Rscript -e "pak::local_install(root = '/workflow.pacta.report')"

# set default run behavior
ENTRYPOINT ["/run-pacta.sh"]
CMD ["input_dir/default_config.json"]
