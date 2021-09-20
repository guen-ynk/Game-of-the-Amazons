import amazons
import cunittest

def main(times=1,inputfile= "4x4",A=3,B=5,MCTS=1000):
    amazons.simulate(times,inputfile,A,B,MCTS, 2000)
    #cunittest.test_mctsamazonlibs6x6()
main()