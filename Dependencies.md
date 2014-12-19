---
title: MeDriAnchor dependencies
author: Steph Locke
output: html_document
---

# TLDR
Works on SQL Server and requires Powershell

# Intro
The aim of the framework is to require as little cost as possible -- as such it'll happily run for free.  We've used modern

# Source code
This project is a SQL Database project and can be accessed using Visual Studio 2012+, including VS2013 Community Edition.

# Database
## SQL Server
Due to the limitations of Anchor Modelling in that it require materialised joins and has a fully tested SQL Server implementation,
currently this framework is geared towards SQL Server, however, the syntax could be amended to work in any RDBMS.

## Editions
The functionality used is all non-deprecated and has been around for a reasonable while. It was developed on SQL Server 2014 Express 
but could be deployed to 2008+

## Permissions
Role-based permissions are utilised within this framework and the primary role [MeDriAnchorRole] is granted:

- CONTROL, INSERT, SELECT, REFERENCES over the schema MeDriAnchor in gateway databases
- CREATE PROCEDURE, CREATE VIEW, CREATE TABLE, REFERENCES over the schema MeDriAnchor in the MeDriAnchor database
- CONTROL, INSERT, SELECT, REFERENCES over the entire DWH database

# ETL
## Powershell
## Editions
## Permissions

# Scheduling
## Windows Task Scheduler
## Editions
## Permissions

# Troubleshooting

# Roadmap