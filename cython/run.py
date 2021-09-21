from git import Repo

import os
import time

import multiprocessing
import amazons


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
    

     

def main(times=1,inputfile= "10x10",A=3,B=5,MCTS=100000,cores=1):
    print(os.cpu_count(), ": CPU COUNT")
 
    times = 1
    cores = 15
    inputfile = "10x10"
    Alist = [2,3,4,3,2,5,4,5]
    Blist = [3,2,3,4,5,2,5,4]
    #MCTSl = [40000]
    MCTS = 1000
    for x in range(len(Alist)):
        processes =[]
        q = multiprocessing.Queue()
        stamp = time.time()
        for i in range(cores):
            p = multiprocessing.Process(target=amazons.main,args=(i, q, times, inputfile, Alist[x], Blist[x], MCTS, 1000)) 
            p.start()
            processes.append(p)
        for p in processes:
            p.join()
        git_push()
main()

    
