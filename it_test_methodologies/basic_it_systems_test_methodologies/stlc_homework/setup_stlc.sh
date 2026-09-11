#!/bin/bash
# setup_stlc.sh — создание рабочей структуры по этапам STLC
WORKDIR="$HOME/stlc_homework"

mkdir -p "$WORKDIR"
mkdir -p "$WORKDIR/01_planning"
mkdir -p "$WORKDIR/02_design"
mkdir -p "$WORKDIR/03_environment"
mkdir -p "$WORKDIR/04_execution"
mkdir -p "$WORKDIR/05_reporting"
mkdir -p "$WORKDIR/06_closure"

touch "$WORKDIR/01_planning/test_plan.md"
touch "$WORKDIR/02_design/test_cases.md"
touch "$WORKDIR/04_execution/run_tests.log"
touch "$WORKDIR/05_reporting/summary.txt"

echo "[$(date '+%F %T')] STLC-структура создана: $WORKDIR"
ls -laR "$WORKDIR"
