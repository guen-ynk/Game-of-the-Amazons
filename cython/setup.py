from setuptools import setup
from Cython.Build import cythonize
import Cython.Compiler.Options
Cython.Compiler.Options.annotate = True
from Cython.Compiler.Options import get_directive_defaults
directive_defaults = get_directive_defaults()

directive_defaults['linetrace'] = True
directive_defaults['binding'] = True
import numpy

setup(
        name="Spitz",
        version="0.2",
        author="Guen Yanik",
        author_email="oeguenarts@gmail.com",
        ext_modules = cythonize("src/*.pyx",build_dir="build",compiler_directives={'binding': True}),
        include_dirs=[numpy.get_include()],
        
    )