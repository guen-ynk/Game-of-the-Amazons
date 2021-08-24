import amazons
import cunittest

def main(times=1,inputfile= "6x6",A=1,B=5,MCTS=1000):
    #amazons.simulate(times,inputfile,A,B,MCTS, 200)
    cunittest.test_mctsamazonlibs6x6()
main()