# workflow.pacta.report

# Description

The Dockerfile in this repository creates an image containing a freshly
cloned copy of `workflow.pacta.report`. It also installs the relevant PACTA R
packages that it depends on.

# Notes

Running PACTA also requires pacta-data, which needs to be mounted into the
container at run-time.

See workflow.pacta for examples of a similar docker container and invokation
