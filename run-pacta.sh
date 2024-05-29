#! /bin/bash

# Set permissions so that new files can be deleted/overwritten outside docker
umask 000

Rscript --vanilla /workflow.pacta.report/pacta_03.R "${1}" \
