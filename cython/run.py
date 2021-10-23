from git import Repo

import os
import time

import multiprocessing
import amazons

'''
@Author: Guen Yanik 
This Script provides functionalities to interact with the Cython compiled amazons: 
- Multithreading and queues for simulations
- Auto Git update
'''



PATH_OF_GIT_REPO = '../.git'  # make sure .git folder is properly configured
COMMIT_MESSAGE = 'RESULTS'

def git_push():
    try:
        repo = Repo(PATH_OF_GIT_REPO)
        repo.index.add(['cython/newres.txt'])
        repo.index.commit(COMMIT_MESSAGE)
        origin = repo.remote(name='origin')
        origin.push()
    except:
        print("err while pushing")
    

'''
    times: simulation per thread
    cores: n cores = n diffrent simulations
    inputfile: board configuration, e.g. "4x4" 
    Alist: List of modes played by White (each element is simulated timexcores times !)
    Blist: List of modes playing against White (Black)
    MCTSl: must have same length as the other lists when used, configures diffrent MCTS Simulationcounts
    ressources: time ressources for each mode 


    MODES:
    0: player -- makes no sense in this scope
    2: deprecated -- no usage
    
    
    1: Mobility eval AlphaBeta
    3: MCTS vanilla
    4: Territorial and positional eval AlphaBeta 
    5: MCTS optimized
'''     

def main():
    print(os.cpu_count(), ": CPU COUNT")
 
    times = 1
    cores = 15
    inputfile = "10x10"
    Alist = [2,5,4,3]
    Blist = [5,2,3,4]
    MCTSl = [10000,10000,10000,10000]
    ressources = [999, 999, 999, 999] # seconds
    for x in range(len(Alist)):
        processes =[]
        q = multiprocessing.Queue()
        stamp = time.time()
        for i in range(cores):
            p = multiprocessing.Process(target=amazons.main,args=(i, q, times, inputfile, Alist[x], Blist[x], MCTSl[x], ressources[x])) 
            p.start()
            processes.append(p)
        for p in processes:
            p.join()
        #git_push()
main()

    
