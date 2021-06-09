# Game-of-the-Amazons
Linux optimized !
### Requirements 
> Cython 
> NumPy

## Usage:
> cd cython/
> &
> python
> &
> import amazons
> &
> amazons.main(3x3) or amazons.main(4x4) ... also see configs/


## Configure Game:
    configs/confignxn.txt:
    n
    mode:pos_amazon_white1 pos_2, 3 ... // white   
    mode:pos_amazon_black1 pos_2, 3 ... // black
    // mode == 0 -> Human , mode == 1 --> AB Move Eval Heuristic, mode == 2 --> AB Territorial Eval Heuristic, mode == 3 MCTS 10.000
    
  
