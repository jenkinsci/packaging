#!/usr/bin/env python3

from jinja2 import Environment, FileSystemLoader

import getopt
import os
import sys


def basename(path):
    return os.path.basename(path)


class IndexGenerator:
    DISTRIBUTIONS = {
        'debian': {
            'extension': '.deb',
            'template': 'header.debian.html'
        },
        'redhat': {
            'extension': '.rpm',
            'template': 'header.redhat.html'
        },
        'opensuse': {
            'extension': '.rpm',
            'template': 'header.opensuse.html'
        },
        'war': {
            'extension': '.war',
            'template': 'header.war.html'
        },
        'windows': {
            'extension': '.msi',
            'template': 'header.msi.html'
        }
    }

    HELP_MESSAGE = '''
    Generate header.html for package distribution site
    It supports debian, redhat and opensuse packages

    indexGenerator.py
        -d <distribution>: Which package distribution to target
        -o <targetDir>: Where to create the HEADER.html

        ex:
        indexGenerator.py
            -d debian
            -o /packages/website/debian
    '''

    packages = []
    targetFile = ''
    template_file = ''
    template_directory = 'templates'
    repositories = []

    def __init__(self, argv):

        self.artifact = os.getenv('ARTIFACTNAME', 'jenkins')
        self.releaseline = os.getenv('RELEASELINE', '')
        self.download_url = os.getenv('URL', 'null')
        self.organization = os.getenv('ORGANIZATION', 'jenkins.io')
        self.product_name = os.getenv('PRODUCTNAME', 'Jenkins')
        self.distribution = os.getenv('OS_FAMILY', 'debian')
        self.target_directory = './target/' + self.distribution
        try:
            opts, args = getopt.getopt(
                argv,
                "hd:o:",
                ["targetDir=", "distribution="]
            )
        except getopt.GetoptError:
            print(self.HELP_MESSAGE)
            sys.exit(2)
        for opt, arg in opts:
            if opt == '-h':
                print(self.HELP_MESSAGE)
                sys.exit()
            elif opt in ("-d", "--distribution"):
                self.distribution = arg
                self.target_directory = './target/' + self.distribution
            elif opt in ("-o", "--targetDir"):
                self.target_directory = arg
                self.targetFile = self.target_directory + "/HEADER.html"

        self.targetFile = self.target_directory + "/HEADER.html"
        self.footer = self.target_directory + '/FOOTER.html'
        self.template_file = self.DISTRIBUTIONS[self.distribution]["template"]
        self.root_dir = os.path.dirname(self.target_directory[0:-1])
        self.root_header = self.root_dir + '/HEADER.html'

    def show_information(self):
        print("Product Name: " + self.product_name)
        print("Download URL: " + self.download_url)
        print("Organization: " + self.organization)
        print("Artifact Name: " + self.artifact)
        print("Distribution: " + self.distribution)
        print('Number of Packages found: ' + str(len(self.packages)))
        print('Template file: ' + self.template_file)
        print('Repository header generated: ' + self.targetFile)
        print('Repository footer generated: ' + self.footer)
        print('Root header generated: ' + self.root_header)

    def generate_root_header(self):

        contexts = {
            'product_name': self.product_name,
            'repositories': self.repositories
        }

        env = Environment(loader=FileSystemLoader(self.template_directory))
        template = env.get_template('header.root.html')

        with open(self.root_header, "w") as f:
            f.write(template.render(contexts))

    def generate_footer(self):

        contexts = {
            'product_name': self.product_name
        }

        env = Environment(loader=FileSystemLoader(self.template_directory))
        template = env.get_template('footer.html')

        with open(self.footer, "w") as f:
            f.write(template.render(contexts))

    def generate_repository_header(self):
        contexts = {
            'product_name': self.product_name,
            'url': self.download_url,
            'organization': self.organization,
            'artifactName': self.artifact,
            'os_family': self.distribution,
            'packages': self.packages,
            'releaseline': self.releaseline
        }
        env = Environment(loader=FileSystemLoader(self.template_directory))
        env.filters['basename'] = basename
        template = env.get_template(self.template_file)

        with open(self.targetFile, "w") as f:
            f.write(template.render(contexts))


if __name__ == "__main__":
    headerGenerator = IndexGenerator(sys.argv[1:])
    headerGenerator.show_information()
    headerGenerator.generate_repository_header()
    headerGenerator.generate_root_header()
    headerGenerator.generate_footer()
