from setuptools import setup
from Cython.Build import cythonize
import Cython.Compiler.Options
Cython.Compiler.Options.annotate = True
import numpy

setup(
        name="Spitz",
        version="0.2",
        author="Guen Yanik",
        author_email="oeguenarts@gmail.com",
        ext_modules = cythonize("src/*.pyx",build_dir="build"),
        include_dirs=[numpy.get_include()]
    )