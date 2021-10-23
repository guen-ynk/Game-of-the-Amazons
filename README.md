# Game-of-the-Amazons
Linux 20.x optimized, datatypes might conflict with other operating systems!
### Requirements 
- Cython 0.29.15
- NumPy
- github 

## Usage:
    cd cython/
    python setup.py build_ext --inplace
    
 ### Single thread:
     specify params in basic.py
     python basic.py

 ### Multithread:
     specify params in run.py!
     python run.py

 ## Configure Game Boards:
    !also see the examples in configs/
    n
    pos_amazon_white1 pos_2, 3 ... // white   
    pos_amazon_black1 pos_2, 3 ... // black
 ## MODES:
    0 : Human
    1 : mobility eval AlphaBeta Pruning
    2 : deprecated
    3 : MCTS vanilla
    4 : territorial & positional eval AlphaBeta Pruning
    5 : MCTS optimized

    
