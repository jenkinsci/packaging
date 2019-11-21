#!/usr/bin/env python3

from jinja2 import Environment, FileSystemLoader

import getopt
import os
import sys
import glob
import datetime


def basename(path):
    return os.path.basename(path)


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
        'opensuse': {
            'extension': '.rpm',
            'template': 'index.opensuse.html'
        },
        'war': {
            'extension': '.war',
            'template': 'index.war.html'
        }
    }

    HELP_MESSAGE = '''
    Generate index.html for package distribution site
    It supports debian, redhat and opensuse packages

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
        self.packages = self.get_packages()
        self.root_dir = os.path.dirname(self.target_directory[0:-1])
        self.root_index = self.root_dir + '/index.html'
        self.repositories = self.get_repositories()

    def get_packages(self):
        packages = []
        file_extension = self.DISTRIBUTIONS[self.distribution]["extension"]

        for file in glob.glob(
                self.binary_directory + "/**/*" + file_extension,
                recursive=True):
            stat = os.stat(file)
            ctime = datetime.datetime.fromtimestamp(stat.st_mtime)
            mtime = datetime.datetime.fromtimestamp(stat.st_ctime)
            packages.append({
                'filename': file.replace(self.binary_directory, ''),
                'creation_time': ctime,
                'last_modified': mtime,
                'size': str(stat.st_size/1000000) + ' MB'
                })

        return packages

    def get_repositories(self):
        repositories = []
        for file in os.scandir(self.root_dir):
            if file.is_dir():
                repositories.append({
                    'name': file.name
                    })

        return repositories

    def show_information(self):
        print("Product Name: " + self.product_name)
        print("Download URL: " + self.download_url)
        print("Organization: " + self.organization)
        print("Artifact Name: " + self.artifact)
        print("Distribution: " + self.distribution)
        print("Repositories: " + str(self.repositories))
        print("Get packages list from: " + self.binary_directory)
        print('Number of Packages found: ' + str(len(self.packages)))
        print('Template file: ' + self.template_file)
        print('Repository index generated: ' + self.targetFile)
        print('Root index generated: ' + self.root_index)

    def generate_root_index(self):

        contexts = {
            'repositories': self.repositories
        }

        env = Environment(loader=FileSystemLoader(self.template_directory))
        env.filters['basename'] = basename
        template = env.get_template('index.root.html')

        with open(self.root_index, "w") as f:
            f.write(template.render(contexts))

    def generate_repository_index(self):
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
        template = env.get_template(self.template_file)

        with open(self.targetFile, "w") as f:
            f.write(template.render(contexts))


if __name__ == "__main__":
    indexGenerator = IndexGenerator(sys.argv[1:])
    indexGenerator.show_information()
    indexGenerator.generate_repository_index()
    indexGenerator.generate_root_index()
