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
    cores = 1
    inputfile = "10x10"
    Filelist = ["4x4","4x4","6x6","6x6","8x8","8x8","10x10","10x10"]
    Alist = [2,4,2,4,2,4,2,4]
    Blist = [4,2,4,2,4,2,4,2]
    MCTSl = [40000,40000,40000,40000,40000,40000,40000,40000]
    #Alist = [A]
    #Blist = [B]
    #MCTSl =[MCTS]
    for x in range(len(Alist)):
        processes =[]
        q = multiprocessing.Queue()
        stamp = time.time()
        for i in range(cores):
            p = multiprocessing.Process(target=amazons.main,args=(i,q,times,Filelist[x],Alist[x],Blist[x],MCTSl[x], 3000)) 
            p.start()
            processes.append(p)
        for p in processes:
            p.join()
        git_push()
main()

    
