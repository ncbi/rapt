Test genome data in this repository should not be used directly in our TeamCity builds that are not directly testing integrity of test input data

Reason: we want to minimize usage of internal resources in our TeamCity build for PGAPX workflows.

The planned flow is this:

This repo -> TeamCity build to publish any changes on S3 -> TeamCity builds for full genome testing consume it from S3
