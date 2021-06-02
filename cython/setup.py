from setuptools import setup
from Cython.Build import cythonize



import Cython.Compiler.Options
Cython.Compiler.Options.annotate = True
import numpy

setup(
    ext_modules = cythonize("amazons.pyx"),
    include_dirs=[numpy.get_include()],
     extra_compile_args = ["-ffast-math"]
     )