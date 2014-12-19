---
title: MeDriAnchor post-deployment scripts
author: Steph Locke
output: html_document
---

#TLDR
Designed to provide a quick rollout of the Anchor Model from scripts to allow rapid creating of different environments

#Intro
The data warehouse can be initially populated and marked-up via a post deployment script (see the Adventure Works 
one in the MeDriAnchor project). In summary this:

* Adds a server of a given type
* Adds a database on that server
* Creates the linked server (if not local to the MeDriAnchor database)
* Reads in the table and columns definitions
* Adds the Anchor markup
* Adds the Attribute markup
* Adds the Knot markup
* Adds the tie markup

This is all that the MeDriAnchor database needs to work with the data source.

#Building a script
The scripts utilise CURSORs to iterate through the different metadata components to insert everything needed for an initial (or full) 
deployment of a section of the datawarehouse whether pointing at a specific source or creating a gateway database first.