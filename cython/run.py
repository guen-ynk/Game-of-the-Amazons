
import os
import time

import multiprocessing
import amazons

def main(times=1,inputfile= "6x6",A=5,B=3,MCTS=100000,cores=1):
    # 23 21 21
    # 25 23 21
    print(os.cpu_count(), ": CPU COUNT")
   # times = int(input("times"))
    #inputfile = input("nxn")
    #A = int(input("A mode"))
    #B = int(input("B mode"))
    #MCTS = int(input("MCTS sim"))
    #cores = int(input("cores#"))
    #times=  2
    #cores = 25
    #inputfile = "10x10"
    #Alist = [3,5,1,3,1,5,4,3,4,5]
    #Blist = [5,3,3,1,5,1,3,4,5,4]
    #MCTSl = [1000,1000,1000,1000,1000,1000,1000,1000,1000,1000]
    Alist = [A]
    Blist = [B]
    MCTSl =[MCTS]
    for x in range(len(Alist)):
        processes =[]
        q = multiprocessing.Queue()
        stamp = time.time()
        for i in range(cores):
            p = multiprocessing.Process(target=amazons.main,args=(i,q,times,inputfile,Alist[x],Blist[x],MCTSl[x], 10)) 
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

    
