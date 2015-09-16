#!/usr/bin/env python

import os
import string
import fnmatch
import sys
from optparse import OptionParser

path = os.path.dirname(os.path.realpath(__file__))
branding_values = dict()

# Read branding environment variable list from branding file
# For each variable read the corresponding env variable and store to branding map
with open(os.path.join(path, 'branding.list'), 'r') as branding:
	lines = filter(lambda x: x and not x.startswith('--'), branding.read().splitlines())
	branding_values = {x:os.environ.get(x) for x in lines}

# Read list of environment variables from file, where each is a path to a file
# And for each read the content of that file to the branding map
# brand-file contents from list of file name env variables and store to branding map as well
with open(os.path.join(path, 'branding-files.list'), 'r') as branding:
	lines = filter(lambda x: x and not x.startswith('--'), branding.read().splitlines())
	for line in lines:
		try:
			# Read path for this line from environment var, and open that file
			f = open(os.environ.get(line), 'r')
			val = f.read()	
			branding_values[line] = val
			f.close()
		except Exception as e:
			branding_values[line] = None

# Do search and replace using string templating for a each file
# Throws Exceptions if I/O fails or substitution is missing vars (safety check)
def apply_templating_to_file(path, branding_map):
	f = open(path, "r+")
	f_content = string.Template(f.read()).substitute(branding_map)
	f.seek(0)
	f.write(f_content)
	f.truncate()
	del f

if (len(sys.argv) != 2):
	raise Exception("Usage: branding.py [file or folder name]")

path = sys.argv[1]

# Apply templating to files or content of folder
if os.path.isfile(path):
	apply_templating_to_file(path, branding_values)
elif os.path.isdir(path):
	# Walks through all files in directory	
	for root, dirnames, filenames in os.walk(path):
		func = lambda x: apply_templating_to_file(os.path.join(root, x), branding_values)
		map(func, filenames)
else:
	raise Exception("Supplied path must be file or directory")
