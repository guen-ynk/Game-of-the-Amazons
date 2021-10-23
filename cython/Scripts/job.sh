#!/usr/bin/env bash
#$ -N  MCTS_10000_SIM
#$ -q all.q
#$ -cwd
#$ -V
#$ -l mem_free=3000M
#$ -t 1-10

source ~/amazons/bin/activate
python ../run.py



