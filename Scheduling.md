\documentclass[a4paper]{article}

\usepackage[english]{babel}
\usepackage[utf8]{inputenc}
\usepackage{amsmath}
\usepackage{graphicx}
\usepackage[colorinlistoftodos]{todonotes}

\title{Scheduling}

\date{\today}

\begin{document}
\maketitle

\section{Introduction}

ETL in the MeDirAnchor database is done via PowerShell by default. This script can be scheduled to run at a given interval by anything that can do this. The initial MeDriAnchor database runs on SQL 2014 Express and the ETL script is scheduled to run every hour by the Windows Task Scheduler. A sample taks is oincluded in MeDriAnchor project folder (ETLRunScheduledTask.xml). The source for the Powershell running script is also in the MeDriAnchor project folder (CrowETLRun.ps1).

\section{Configuration}

The ETL running script is environment aware. In the MeDriAnchor database you can have multiple DWH destinations, one for each environment or just one for all. Each environment will create objects in it's own schema, so you simply need to configure the running script once for each environmant you wish to use.

\section{Prerequisites}

The only prerequisite for ETL running with PowerShell is that the machine that runs the script has PowerShell on and the permissions to run PowerShell scripts.

\section{Setting up schedules}

Before setting the schedules, you need to run the script for the given environment manually to see how long it takes, only then will you know what a sensible time between runs would be. There is also a setting in the settings tables that controlls after how many hours a batch should be marked as complete (to saver the process never running, as it always checks to see that no ther batch is running). When initiating a batch, the first thing that the system does is to check for in-progress batches that are over n hours old and flag them as finished, to enable other batches to then run. The default is two hours.

\section{Turning them on}

\section{Troubleshooting}

\section{Roadmap}

\end{document}