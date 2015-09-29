#!/usr/bin/env python

import os
import string
import fnmatch
import sys
from optparse import OptionParser

# Applies branding to files/folders with simple templating
# Usage is 'python branding.py {file or folder}'
# Env variables to use are given in BRANDING_ENV_VARIABLE_LIST
# Env variables giving *paths* to read content for templating are given in BRANDING_ENV_PATH_LIST
# Author Sam Van Oort <samvanoort@gmail.com> 

BRANDING_ENV_VARIABLE_LIST = 'branding.list'
BRANDING_ENV_PATH_LIST = 'branding-files.list'

def clean_text_lines(textcontent):
	""" Splits file content by line boundaries, strips leading/trailing whitespace, 
	    and removes comments with # and -- prefixes and whitespace lines """
	lines = map(lambda x: x.strip(), textcontent.splitlines())
	lines = filter(lambda x: x and not x.startswith('#') and not x.startswith('--'), lines)
	return lines

def read_env_variable_list(path):
	""" Read a list of environment variables from a file (one per line) and get a dict of var:value """
	with open(path, 'r') as env_file:
		lines = clean_text_lines(env_file.read())
		branding_values = {x:os.environ.get(x) for x in lines}
	return branding_values

def read_file_content(value_path_dictionary):
	""" For a {variable_name:file_path} dictionary, read each file and 
	    return a dictionary of {variable:file_content}

	    If paths are null/empty, they are not read to result. """
	output = dict()
	filtered = filter(lambda x: x[1] is not None and len(x[1].strip()) > 0, value_path_dictionary.items())
	for variable, path in filtered:
		f = open(path, 'r')
		output[variable] = f.read()
		f.close()
	return output

def read_branding_variables(base_path, env_variables_list, file_variables_list):
	""" Read branding variables from files/environment and return result """

	raw_variables = read_env_variable_list(os.path.join(base_path, env_variables_list))
	file_variables = read_env_variable_list(os.path.join(base_path, file_variables_list))
	raw_variables.update(read_file_content(file_variables))  # Add file content variables
	return raw_variables

def apply_templating_to_file(path, branding_map):
	""" Do IN-PLACE search and replace using string templating for a each file
		Throws Exceptions if I/O fails or substitution is missing vars (safety check)
	"""
	f = open(path, "r+")
	f_content = string.Template(f.read()).substitute(branding_map)
	f.seek(0)
	f.write(f_content)
	f.truncate()  # This removes any original content beyond the end of templated content
	f.close()

def apply_templating_to_folder(path, branding_map):
	""" Walks through all contents of folder recursively, and applies templating """	
	for root, dirnames, filenames in os.walk(path):
		func = lambda x: apply_templating_to_file(os.path.join(root, x), branding_map)
		map(func, filenames)

# Importable as a library without executing it
if(__name__ == '__main__'):
	if (len(sys.argv) != 2):
		raise Exception("Usage: branding.py [file or folder name]")
	path = sys.argv[1]

	mypath = os.path.dirname(os.path.realpath(__file__))
	branding_values = read_branding_variables(mypath, BRANDING_ENV_VARIABLE_LIST, BRANDING_ENV_PATH_LIST)

	# Remove branding values with nothing set so we fail early if they are used in a template
	branding_values = dict(filter (lambda x: x[1], branding_values.items()))

	# Apply templating to files or content of folder
	if os.path.isfile(path):
		apply_templating_to_file(path, branding_values)
	elif os.path.isdir(path):
		apply_templating_to_folder(path, branding_values)
	else:
		raise Exception("Supplied path must be file or directory")
