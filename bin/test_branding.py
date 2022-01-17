#!/usr/bin/env python3

import branding
import os
import string
import tempfile
import unittest

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

# NOMATCH is a section that should *not* be treated as a variable for substitution to 
# Avoid issues with curly braces
TEMPLATED_CONTENT = "My @@VAR@@ is @@FILECONTENT@@ and I have @@@@ESCAPES@@ and @@{NOMATCH}@@ stuff"
TEMPLATE_VARS = {'VAR': 'SPECIAL', 'FILECONTENT': 'gooooooober'}

# Shows that substitutions were performed, and NOMATCH does not get handled as a substitution variable
TEMPLATE_EXPECTED = 'My SPECIAL is gooooooober and I have @@ESCAPES@@ and @@{NOMATCH}@@ stuff'

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
        temp.write(SHORT_VARS.encode())
        temp.seek(0)
        os.environ['TESTVAR']='testvalue'
        vals = branding.read_env_variable_list(temp.name)
        self.assertEqual(1, len(vals))
        self.assertEqual('testvalue', vals['TESTVAR'])
    
    def test_read_file_content(self):
        """ Write file and then read, using path from env """
        temp = tempfile.NamedTemporaryFile()
        temp.write(RAW_CONTENT.encode())
        temp.seek(0)

        os.environ['FILEPATH']=temp.name
        vals = branding.read_file_content({'FILEPATH': temp.name})
        self.assertEqual(RAW_CONTENT, vals['FILEPATH'])

    def test_templating(self):
        output = branding.apply_template(TEMPLATED_CONTENT, TEMPLATE_VARS)
        self.assertEqual(TEMPLATE_EXPECTED, output)

    def test_missing_variable(self):
        """ Prove branding will fail if branding variable is undefined """

        try:
            output = branding.apply_template('My @@UNDEFINED_VALUE@@ is going to fail', {'going': 'to fail'})
            self.fail("Should throw KeyError")
        except KeyError:
            pass

    def test_in_place_templating(self):
        temp = tempfile.NamedTemporaryFile()
        temp.write(TEMPLATED_CONTENT.encode())
        temp.seek(0)
        branding.apply_templating_to_file(temp.name, TEMPLATE_VARS)
        temp.seek(0)
        self.assertEqual(TEMPLATE_EXPECTED, temp.read().decode())


if __name__ == '__main__':
    unittest.main()