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

def main():
    print(os.cpu_count(), ": CPU COUNT")
 
    times = 1
    cores = 1
    inputfile = "10x10"
    Alist = [2,4,2,4,2,4,2,4,2,4,2,4]
    Blist = [4,2,4,2,4,2,4,2,4,2,4,2]
    MCTSl = [0,1,2,3,4,5,6,7,8,9,10,11]
    Timel = [5,5,10,10,20,20,40,40,60,60]
    processes =[]
    q = multiprocessing.Queue()
    for x in range(len(Alist)):
        p = multiprocessing.Process(target=amazons.main,args=(x,q,times,inputfile,Alist[x],Blist[x],MCTSl[x],Timel[x])) 
        p.start()
        processes.append(p)
    for p in processes:
        p.join()
    git_push()

main()