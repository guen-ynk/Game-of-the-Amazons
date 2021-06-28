# Game-of-the-Amazons
Linux optimized !
### Requirements 
- Cython 
- NumPy

## Usage:
 ### One Thread example [ 1 game, 8x8 Board, white plays with mode 2, black plays with mode 3, MCTS iterations == 10000]:

    cd cython/
    python setup.py build_ext --inplace
    ..
    python
    >>import amazons
    >>amazons.simulate(1, "8x8", 2, 3, 10000) 

    amazons.main(3x3) or amazons.main(4x4) ... also see configs/
 ### Multithread:
     specify params in run.py!
     cd cython/
     python setup.py build_ext --inplace
     ..
     python run.py

 ## Configure Game Boards:
    !also see the examples in configs/
    n
    mode:pos_amazon_white1 pos_2, 3 ... // white   
    mode:pos_amazon_black1 pos_2, 3 ... // black
    // mode == 0 -> Human , mode == 1 --> AB Move Eval Heuristic, mode == 2 --> AB Territorial Eval Heuristic, mode == 3 MCTS 10.000
    
  
