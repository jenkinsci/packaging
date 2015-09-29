#!/usr/bin/env python

import unittest
import branding
import tempfile
import os
import string

RAW_CONTENT = """
PRODUCTNAME
    ARTIFACTNAME

SUMMARY
 PORT

AUTHOR
# Not here
LICENSE
 HOMEPAGE  
CHANGELOG_PAGE
----------------------------------

SUSE_URL
  # INVALID
DEB_URL
LICENSE_TEXT

"""

SHORT_VARS = """
TESTVAR
"""

TEMPLATED_CONTENT = """
My $VAR is $FILECONTENT
"""

class TestBranding(unittest.TestCase):

    def test_clean_lines(self):
        cleaned = set(branding.clean_text_lines(RAW_CONTENT))
        expected = {'PRODUCTNAME', 'ARTIFACTNAME', 'SUMMARY', 
          'PORT', 'AUTHOR', 'LICENSE', 'HOMEPAGE', 'CHANGELOG_PAGE', 
          'SUSE_URL', 'DEB_URL', 'LICENSE_TEXT'
        }
        invalid_results = cleaned ^ expected  # Items in one set but not the other
        self.assertFalse(invalid_results)

    def test_read_env_list(self):
        temp = tempfile.NamedTemporaryFile()
        temp.write(SHORT_VARS)
        temp.seek(0)
        os.environ['TESTVAR']='testvalue'
        vals = branding.read_env_variable_list(temp.name)
        self.assertEqual(1, len(vals))
        self.assertEqual('testvalue', vals['TESTVAR'])
    
    def test_read_file_content(self):
        """ Write file and then read, using path from env """
        temp = tempfile.NamedTemporaryFile()
        temp.write(RAW_CONTENT)
        temp.seek(0)

        os.environ['FILEPATH']=temp.name
        vals = branding.read_file_content({'FILEPATH': temp.name})
        self.assertEqual(RAW_CONTENT, vals['FILEPATH'])

    def test_in_place_templating(self):
        temp = tempfile.NamedTemporaryFile()
        temp.write(TEMPLATED_CONTENT)
        temp.seek(0)

        branding_vars = {'VAR': 'SPECIAL', 'FILECONTENT': 'gooooooober'}
        branding.apply_templating_to_file(temp.name, branding_vars)
        temp.seek(0)
        self.assertEqual(string.Template(TEMPLATED_CONTENT).substitute(branding_vars), temp.read())


if __name__ == '__main__':
    unittest.main()