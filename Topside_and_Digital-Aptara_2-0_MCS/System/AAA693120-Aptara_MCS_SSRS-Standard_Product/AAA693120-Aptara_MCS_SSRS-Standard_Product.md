---
title: "Aptara MCS"
subtitle: "SSRS Standard Product"
doc_number: "AAA693120"
revision: "001"
author: "Systems Engineering"
date: "July 13, 2026"
copyright_year: "2026"
confidentiality: "Baker Hughes Confidential"
---

# Document Overview

This document defines the standard product requirements for the Aptara Modular
Control System (MCS) Subsea Supervisory and Reporting System (SSRS). It provides
a common technical baseline for system design, implementation, verification,
and project-specific configuration.

## Purpose

The purpose of the SSRS is to collect operational data from connected control
system components, present system status to authorized users, and retain the
information required for engineering analysis and operational reporting.

::: {.note}
Revision 001 adds availability monitoring, backup integrity, and recovery
verification requirements. Project-specific deviations shall be documented
separately and shall not change the standard product requirements without
formal review.
:::

## Scope

The standard SSRS product includes:

- Acquisition of status, alarm, event, and process data.
- Operator access to current and historical system information.
- Generation of standard operational and maintenance reports.
- Controlled exchange of data with approved external systems.
- User authentication and role-based authorization.

The following items are outside the scope of this document:

- Project-specific tag databases.
- Customer network infrastructure outside the SSRS boundary.
- Third-party reporting packages not supplied as part of the standard product.

# System Description

## Functional Architecture

The SSRS consists of application services, data services, operator interfaces,
and communication interfaces. The system shall support deployment on an
approved industrial computing platform and shall operate without requiring
continuous access to an external cloud service.

::: {.table-cols width="0.22,0.36,0.42"}
Table: Standard SSRS functional components {#tbl:functional-components}

| Component | Primary Function | Typical Interface |
|---|---|---|
| Data Acquisition Service | Collect and validate source data | OPC UA or approved project protocol |
| Historian | Retain time-series values and events | Internal data service |
| Reporting Service | Generate scheduled and on-demand reports | Web user interface |
| Operator Interface | Display status, alarms, and trends | HTTPS |
| Administration Service | Manage users, roles, and configuration | Restricted HTTPS interface |
:::

## Operating Modes

The SSRS shall support the following operating modes:

1. **Normal operation** - all configured services are available and data is
   collected continuously.
2. **Degraded operation** - one or more external interfaces are unavailable.
   Local data collection and reporting services shall continue operating where
   their required dependencies remain available.
3. **Maintenance mode** - authorized personnel may stop selected services for
   backup, configuration, or software maintenance.
4. **Recovery mode** - services and retained data are restored following a
   controlled recovery procedure.

# Product Requirements

## General Requirements

| ID | Requirement |
|---|---|
| SSRS-GEN-001 | The SSRS shall display the current availability of each configured data source. |
| SSRS-GEN-002 | The SSRS shall time-stamp collected records using the configured system time source. |
| SSRS-GEN-003 | The SSRS shall retain an audit record of security-relevant administrative actions. |
| SSRS-GEN-004 | The SSRS shall recover automatically after restoration of the computing platform. |
| SSRS-GEN-005 | The SSRS shall prevent unauthorized modification of controlled configuration data. |
| SSRS-GEN-006 | The SSRS shall monitor critical application services and report an unavailable service to authorized users. |
| SSRS-GEN-007 | The SSRS shall verify the integrity of a completed configuration backup before reporting the backup as successful. |

## Data and Reporting Requirements

| ID | Requirement |
|---|---|
| SSRS-DAT-001 | The SSRS shall retain process values at the configured sampling interval. |
| SSRS-DAT-002 | The SSRS shall preserve alarm and event time order during normal operation. |
| SSRS-DAT-003 | Authorized users shall be able to export approved report data in PDF and CSV formats. |
| SSRS-DAT-004 | Reports shall identify the report period, generation time, and data source. |
| SSRS-DAT-005 | Buffered records shall be forwarded in chronological order after restoration of an interrupted data-source connection. |

## Security Requirements

| ID | Requirement |
|---|---|
| SSRS-SEC-001 | Each interactive user shall authenticate using an individually assigned account. |
| SSRS-SEC-002 | Access permissions shall be assigned through approved user roles. |
| SSRS-SEC-003 | Communication with browser-based clients shall use encrypted HTTPS sessions. |
| SSRS-SEC-004 | Security logs shall be available to authorized administrators. |

# External Interfaces

## Control System Interface

The control system interface shall provide the configured process values,
equipment states, alarms, and events. Loss of this interface shall be reported
to the operator within the configured monitoring interval and shall not corrupt
previously retained data.

## User Interface

The user interface shall provide navigation to dashboards, trends, alarms,
reports, and administrative functions according to the signed-in user's role.

## Time Synchronization

The SSRS computing platform shall synchronize with the approved project time
source. All displayed and exported timestamps shall identify the configured
time basis.

# Verification

The revision 001 baseline shall be verified using the methods below.

::: {.table-cols width="0.18,0.18,0.64"}
Table: Initial verification matrix {#tbl:verification-matrix}

| Verification Area | Method | Acceptance Criterion |
|---|---|---|
| Installation | Inspection | Required services and configuration files are present. |
| Data acquisition | Test | Configured values are received and time-stamped correctly. |
| Alarms and events | Test | Generated test events appear in the correct sequence. |
| Reporting | Demonstration | An authorized user can generate and export a standard report. |
| Access control | Test | Each test role can access only its permitted functions. |
| Recovery | Test | Services recover after a controlled platform restart. |
| Backup integrity | Test | A valid backup is accepted and an intentionally corrupted backup is rejected. |
| Interface recovery | Test | Buffered records are transferred in time order after communication is restored. |
:::

# Revision Notes

Revision 001 extends the SSRS Standard Product baseline with service-availability
monitoring, backup-integrity verification, and deterministic recovery of
buffered records after an interface interruption.
