
import os
import time

import multiprocessing
import amazons

def main(times=5,inputfile= "6x6",A=1,B=3,MCTS=100,cores=4):
    print(os.cpu_count(), ": CPU COUNT")
    times = int(input("times"))
    inputfile = input("nxn")
    A = int(input("A mode"))
    B = int(input("B mode"))
    MCTS = int(input("MCTS sim"))
    cores = int(input("cores#"))
    processes =[]
    q = multiprocessing.Queue()
    stamp = time.time()
    for _ in range(cores):
        p = multiprocessing.Process(target=amazons.main,args=(q,times,inputfile,A,B,MCTS)) 
        p.start()
        processes.append(p)
    for p in processes:
        p.join()

    results = [q.get() for j in processes]
    print(results)

    f = open("resn.txt", "a")
    f.write(str(time.time()-stamp)+"\n"+"white wins: "+str(sum(results))+"\n"+str(times)+ "A: "+str(A)+"B: "+str(B)+"MCTS: "+str(MCTS)+"\n\n")
    f.close()
main()

    