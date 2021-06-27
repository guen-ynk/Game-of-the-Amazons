
import os
import time

import multiprocessing
import amazons

def main(times=30,inputfile= "4x4",A=3,B=1,MCTS=1000,cores=2):
    print(os.cpu_count(), ": CPU COUNT")
   # times = int(input("times"))
    #inputfile = input("nxn")
    #A = int(input("A mode"))
    #B = int(input("B mode"))
    #MCTS = int(input("MCTS sim"))
    #cores = int(input("cores#"))
    times=  10
    cores = 5
    inputfile = "8x8"
    Alist = [1,3,2,3]
    Blist = [3,1,3,2]
    MCTSl = [70000,70000,70000,70000]
    #Alist = [A]
    #Blist = [B]
    #MCTSl =[MCTS]
    for x in range(len(Alist)):
        processes =[]
        q = multiprocessing.Queue()
        stamp = time.time()
        for i in range(cores):
            p = multiprocessing.Process(target=amazons.main,args=(i,q,times,inputfile,Alist[x],Blist[x],MCTSl[x])) 
            p.start()
            processes.append(p)
        for p in processes:
            p.join()

        results = [q.get() for j in processes]
        print(results)

        f = open("testresults.txt", "a")
        f.write(str(time.time()-stamp)+"\n"+"white wins: "+str(sum(results))+"\n"+str(times*cores)+ "A: "+str(Alist[x])+"B: "+str(Blist[x])+"MCTS: "+str(MCTSl[x])+"\n"+inputfile+str(x)+"\n")
        f.close()
main()

    
