# library
import numpy as np
from PIL import Image

GAME = np.array((
    (-1, -1, -1, -1, -1, 2, -1, -1, 0, -1),
    (-1, 2, -1, -1, -1, -1, -1, -1, 1, -1),
    (-1, -1, -1, -1, -1, -1, -1, -1, -1, -1),
    (-1, -1, -1, -1, -1, -1, 1, -1, -1, -1),
    (-1, -1, -1, -1, -1, -1, -1, -1, -1, -1),
    (-1, -1, -1, -1, -1, -1, -1, -1, -1, 2),
    (-1, -1, -1, -1, -1, -1, -1, -1, -1, -1),
    (1, -1, -1, -1, -1, -1, -1, -1, -1, 1),
    (-1, -1, -1, -1, 0, -1, 2, -1, -1, -1),
    (-1, -1, -1, -1, -1, -1, -1, -1, 0, -1)
))
# opening up of images
Arrow = Image.open("arrow.png")
EGREEN = Image.open("green.png")
EGREY = Image.open("grey.png")
GREENA = Image.open("greenA.png")
GREYA = Image.open("greyA.png")
GREENB = Image.open("greenB.png")
GREYB = Image.open("greyB.png")
A = Image.open("A.png")
B = Image.open("B.png")
C = Image.open("C.png")
D = Image.open("D.png")
E = Image.open("E.png")
F = Image.open("F.png")
G = Image.open("G.png")
H = Image.open("H.png")
I = Image.open("I.png")
J = Image.open("J.png")
n0 = Image.open("0.png")
n1 = Image.open("1.png")
n2 = Image.open("2.png")
n3 = Image.open("3.png")
n4 = Image.open("4.png")
n5 = Image.open("5.png")
n6 = Image.open("6.png")
n7 = Image.open("7.png")
n8 = Image.open("8.png")
n9 = Image.open("9.png")
n10 = Image.open("10.png")

ALPHA = list([A, B, C, D, E, F, G, H, I, J])
NUMMERICAL = list([n1, n2, n3, n4, n5, n6, n7, n8, n9, n10])
NUMMERICAL.reverse()
# creating a new image and pasting
# the images
BOARD = Image.new("RGB", (1100, 1100), "white")
for n, alpha in enumerate(ALPHA):
    BOARD.paste(alpha, ((n + 1) * 100, 0))
flag = True
for x in range(10):
    if NUMMERICAL[x].size == (50, 100):
        BOARD.paste(NUMMERICAL[x], (50, (x + 1) * 100))
    else:
        BOARD.paste(NUMMERICAL[x], (0, (x + 1) * 100))

    for y in range(10):
        if flag:
            if y % 2:
                if GAME[x, y] == 0:
                    BOARD.paste(EGREEN, ((y + 1) * 100, (x + 1) * 100))
                if GAME[x, y] == 1:
                    BOARD.paste(GREENA, ((y + 1) * 100, (x + 1) * 100))
                if GAME[x, y] == 2:
                    BOARD.paste(GREENB, ((y + 1) * 100, (x + 1) * 100))
                if GAME[x, y] == -1:
                    BOARD.paste(Arrow, ((y + 1) * 100, (x + 1) * 100))
            else:
                if GAME[x, y] == 0:
                    BOARD.paste(EGREY, ((y + 1) * 100, (x + 1) * 100))
                if GAME[x, y] == 1:
                    BOARD.paste(GREYA, ((y + 1) * 100, (x + 1) * 100))
                if GAME[x, y] == 2:
                    BOARD.paste(GREYB, ((y + 1) * 100, (x + 1) * 100))
                if GAME[x, y] == -1:
                    BOARD.paste(Arrow, ((y + 1) * 100, (x + 1) * 100))

        else:
            if not y % 2:
                if GAME[x, y] == 0:
                    BOARD.paste(EGREEN, ((y + 1) * 100, (x + 1) * 100))
                if GAME[x, y] == 1:
                    BOARD.paste(GREENA, ((y + 1) * 100, (x + 1) * 100))
                if GAME[x, y] == 2:
                    BOARD.paste(GREENB, ((y + 1) * 100, (x + 1) * 100))
                if GAME[x, y] == -1:
                    BOARD.paste(Arrow, ((y + 1) * 100, (x + 1) * 100))
            else:
                if GAME[x, y] == 0:
                    BOARD.paste(EGREY, ((y + 1) * 100, (x + 1) * 100))
                if GAME[x, y] == 1:
                    BOARD.paste(GREYA, ((y + 1) * 100, (x + 1) * 100))
                if GAME[x, y] == 2:
                    BOARD.paste(GREYB, ((y + 1) * 100, (x + 1) * 100))
                if GAME[x, y] == -1:
                    BOARD.paste(Arrow, ((y + 1) * 100, (x + 1) * 100))

    flag = not flag
BOARD.save(r'out.png')
'''
GAME = np.array((
    (-1, - 1, - 1, -1, -1, - 1, - 1, 0, - 1, 0),
    (-1, - 1, 2, - 1, - 1, - 1, - 1, - 1, 0, - 1),
    (0, - 1, - 1, -1, 0, 0, 1, -1, 0, 0),
    (0, 0, -1, -1, -1, -1, -1, 0, 0, -1),
    (-1, -1, -1, -1, -1, -1, -1, 0, 0, 0),
    (0, -1, -1, -1, 2, 1, -1, -1, -1, 0),
    (0, -1, -1, 2, -1, -1, -1, -1, 0, 0),
    (0, 1, -1, -1, -1, 0, -1, -1, 0, 0),
    (0, 0, -1, 2, -1, -1, -1, -1, 0, -1),
    (-1, -1, -1, -1, -1, -1, 0, 1, 0, -1)
))
'''
