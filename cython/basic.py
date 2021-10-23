import amazons
import cunittest

'''
    @Author: Guen Yanik
    This code provides acces to the two entry points of this compiled Cython project:
    The Amazons -- configure Game and play/simulate 
    cunittest -- custom testclass see cunittest.pyx
'''
        # how often, configuration, White mode, Black modem, MCTS simulations, time limit in s 
def main(times=1,inputfile= "10x10",A=5,B=5,MCTS=9999999, ressources=12):
    amazons.simulate(times,inputfile,A,B,MCTS, ressources)
    #cunittest.test_mctsamazonlibs6x6()
main()