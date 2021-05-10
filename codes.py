import numpy as np

if __name__ == '__main__':
    a = np.array([1,2,3])
    tmp = np.zeros((3, 3), dtype=int)
    tmp[(0, 2)] = 2
    tmp[(0, 0)] = 2

    print(tmp)
    indx = np.arange(3)
    print(indx)
    s = (0, 0)
    d = (2, 2)
    op = (1, 1)

    les = False if not op[0] else indx[max(0, min(s[0] + op[0], d[0])):min(10, max(s[0], d[0] + op[0]))][::op[0]]
    res = False if not op[1] else indx[max(0, min(s[1] + op[1], d[1])):min(10, max(s[1], d[1] + op[1]))][::op[1]]
    print(not np.any(tmp[(les, 0)]))
    whites = tmp[np.where(tmp == 2)]
    whites = np.where(tmp == 2)

    ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
    xx = np.array(list(np.array([a, b]) for (a, b) in zip(*whites)))+1
    print("xx", xx)
    yy = list(map(lambda x: x + ops, xx))
    print(yy)
    yyy = np.pad(tmp, 1, "constant", constant_values=-1)
    print(yyy)
    zz = np.array(list(map(lambda x: yyy[(tuple(zip(*x)))], yy)))
    print(zz)
    print(np.any([[-1 , 1, - 1, - 1 ,- 1,- 1 , 1  ,2],
     [-1, - 1 , 1, - 1 , 2 ,- 1 ,- 1 ,- 1]]))