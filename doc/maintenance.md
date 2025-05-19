---
title: KDK maintenance
---

[[_TOC_]]

## Accessing CI/CD variables

Project CI/CD variables are set in <https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/settings/ci_cd>. All users with the Maintainer role
on this project can access them.

Group CI/CD variables are set in the [`khulnasoft-org` group](https://khulnasoft.com/khulnasoft-org), and only users with the Maintainer role on that group
can access them.

## Rotate the `KHULNASOFT_LICENSE_KEY` variable

1. Request a new license to store in the variable. For more information, see
   [Working on KhulnaSoft EE (developer licenses)](https://handbook.khulnasoft.com/handbook/engineering/developer-onboarding/#working-on-khulnasoft-ee-developer-licenses).
1. Update `KHULNASOFT_LICENSE_KEY` variable at [KDK CI/CD Settings](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/settings/ci_cd).
1. Contact the Support Team to revoke the existing license.
