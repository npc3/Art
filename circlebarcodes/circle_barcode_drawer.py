# circle_barcode_drawer.py
# Copyright Nate Cybulski, 2013
# Draws circular barcodes according to different patterns

from cairo import *
from math import *
import random

b = y = True
w = n = False

def sieve(limit):
    sievelen = limit
    sievehas = [True] * sievelen
    sieve = []
    for i in range(2, sievelen):
        if sievehas[i]:
            for j in range(i * 2, sievelen, i):
                sievehas[j] = False
            sieve.append(i)
    sievehas[0] = False
    sievehas[1] = False
    return sieve, sievehas

list_of_primes, prime_bools = sieve(10000)

def testprimes(n): return prime_bools[n]

def segprimes(n): return list_of_primes[n]

def tri(n): return sum(range(n+2))

def fib(n):
    def fibsub(n):
        if n == 0:
            return 0, 1
        a, b = fibsub(n-1)
        return b, a+b
    return fibsub(n)[1]

def odds(n): return 2 * n + 1

def evens(n): return 2 * n + 2

def crapsin(n):
    return int(16*sin(n) + 32) * n

def bin8(n):
    out = bin(n)[2:]
    return (8 - len(out)) * '0' + out

def testfunc_from_string(s):
    l = [int(x) for x in ''.join([bin8(ord(c)) for c in s])]
    print len(l)
    def stringfunc(i):
        try:
            return l[i]
        except IndexError:
            return False
    return stringfunc

def multiples_of(n):
    return lambda i: i%n == 0

alts = multiples_of(2)

def pattern(*args):
    return lambda n: args[n%len(args)]

major_notes = pattern(y, n, y, n, y, y, n, y, n, y, n, y)

def drawseg(ctx, ring, nsegs, seg, x, y, lw):
    radius = lw * (0.5 + ring)
    rads = 2*pi
    segarc = rads/nsegs
    start = seg * segarc - 0.25 * rads
    end = start + segarc
    ctx.arc(x, y, radius, start, end)

def drawit(segfunc, testfunc, lw, outfile, outfiledim):
    surf = SVGSurface(outfile, outfiledim, outfiledim)
    ctx = Context(surf)
    _, _, scrw, scrh = ctx.clip_extents()
    xmid = scrw/2
    ymid = scrh/2
    ctx.set_line_width(lw)

    segsdone = 0
    for i in range(0, outfiledim / (lw * 2)):
        nsegs = segfunc(i)
        for j in range(nsegs):
            if testfunc(segsdone):
                ctx.set_source_rgb(0, 0, 0)
            else:
                ctx.set_source_rgb(255, 255, 255)
            segsdone += 1
            drawseg(ctx, i, nsegs, j, xmid, ymid, lw)
            ctx.stroke()

    surf.flush()
    surf.finish()
    print segsdone

def main():
    outfile = raw_input("Name of output file: ") or "crap.svg"
    outdim = int(raw_input("Dimesions of output file: ") or "640")
    lw = int(raw_input("Line width: ") or "20")
    segfunc = input("Segfunc: ")
    testfunc = input("Testfunc: ")
    drawit(segfunc, testfunc, lw, outfile, outdim)

if __name__ == '__main__':
    main()
