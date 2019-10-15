#!/usr/bin/env python

from jinja2 import Environment, FileSystemLoader

import getopt
import os
import sys
import glob
import datetime


class IndexGenerator:
    DISTRIBUTIONS = {
        'debian': {
            'extension': '.deb',
            'template': 'index.debian.html'
        },
        'redhat': {
            'extension': '.rpm',
            'template': 'index.redhat.html'
        },
        'suse': {
            'extension': '.rpm',
            'template': 'index.suse.html'
        }
    }

    HELP_MESSAGE = '''
    Generate index.html for package distribution site
    It supports debian, redhat and suse packages

    indexGenerator.py
        -b <binaries>: Directory where to get a list of packages>
        -d <distribution>: Which package distribution to target
        -o <targetDir>: Where to create the index.html

        ex:
        indexGenerator.py
            -b /packages/binary/debian
            -d debian
            -o /packages/website/debian
    '''

    binary_directory = ''
    packages = []
    targetFile = ''
    template_file = ''
    template_directory = 'templates'

    def __init__(self, argv):

        self.artifact = os.getenv('ARTIFACTNAME', 'jenkins')
        self.download_url = os.getenv('URL', 'null')
        self.organization = os.getenv('ORGANIZATION', 'jenkins.io')
        self.product_name = os.getenv('PRODUCTNAME', 'Jenkins')
        self.distribution = os.getenv('OS_FAMILY', 'debian')
        self.target_directory = './target/' + self.distribution
        try:
            opts, args = getopt.getopt(
                argv,
                "hd:o:b:",
                ["targetDir=", "binaryDir=", "distribution="]
            )
        except getopt.GetoptError:
            print(self.HELP_MESSAGE)
            sys.exit(2)
        for opt, arg in opts:
            if opt == '-h':
                print(self.HELP_MESSAGE)
                sys.exit()
            elif opt in ("-b", "--binaryDir"):
                self.binary_directory = arg
            elif opt in ("-d", "--distribution"):
                self.distribution = arg
                self.target_directory = './target/' + self.distribution
            elif opt in ("-o", "--targetDir"):
                self.target_directory = arg
                self.targetFile = self.target_directory + "/index.html"

        self.targetFile = self.target_directory + "/index.html"
        self.template_file = self.DISTRIBUTIONS[self.distribution]["template"]
        self.update_packages_list()

    def update_packages_list(self):
        file_extension = self.DISTRIBUTIONS[self.distribution]["extension"]

        for file in glob.glob(self.binary_directory + "/*" + file_extension):
            stat = os.stat(file)
            ctime = datetime.datetime.fromtimestamp(stat.st_mtime)
            mtime = datetime.datetime.fromtimestamp(stat.st_ctime)
            self.packages.append({
                'filename': file,
                'creation_time': ctime,
                'last_modified': mtime,
                'size': str(stat.st_size/1000000) + ' MB'
                })

    def show_information(self):
        print("Product Name: " + self.product_name)
        print("Download URL: " + self.download_url)
        print("Organization: " + self.organization)
        print("Artifact Name: " + self.artifact)
        print("Distribution: " + self.distribution)
        print("Get packages list from: " + self.binary_directory)
        print('Number of Packages found: ' + str(len(self.packages)))
        print('Template file: ' + self.template_file)
        print('Generated index.html: ' + self.targetFile)

    def write_template(self):
        contexts = {
            'product_name': self.product_name,
            'url': self.download_url,
            'organization': self.organization,
            'artifactName': self.artifact,
            'os_family': self.distribution,
            'packages': self.packages
        }
        env = Environment(loader=FileSystemLoader(self.template_directory))
        template = env.get_template(self.template_file)

        with open(self.targetFile, "w") as f:
            f.write(template.render(contexts))


if __name__ == "__main__":
    indexGenerator = IndexGenerator(sys.argv[1:])
    indexGenerator.show_information()
    indexGenerator.write_template()
