#!/usr/bin/env python3

import getopt
import jinja2
import os
import pathlib
import sys


def basename(path):
    return os.path.basename(path)


class IndexGenerator:
    DISTRIBUTIONS = {
        "debian": {
            "extension": ".deb",
            "template": "header.debian.html",
            "web_url": os.getenv("DEB_URL"),
        },
        "redhat": {
            "extension": ".rpm",
            "template": "header.redhat.html",
            "web_url": os.getenv("RPM_URL"),
        },
        "opensuse": {
            "extension": ".rpm",
            "template": "header.opensuse.html",
            "web_url": os.getenv("SUSE_URL"),
        },
        "war": {"extension": ".war", "template": "header.war.html", "web_url": "unset"},
        "windows": {
            "extension": ".msi",
            "template": "header.msi.html",
            "web_url": "unset",
        },
    }

    HELP_MESSAGE = """
    Generate header.html for package distribution site
    It supports debian, redhat and opensuse packages

    indexGenerator.py
        -d <distribution>: Which package distribution to target
        -o <targetDir>: Where to create the HEADER.html

        ex:
        indexGenerator.py
            -d debian
            -o /packages/website/debian
    """

    packages = []
    targetFile = ""
    template_file = ""
    template_directory = "templates"
    repositories = []

    def __init__(self, argv):

        self.artifact = os.getenv("ARTIFACTNAME", "jenkins")
        self.releaseline = os.getenv("RELEASELINE", "")
        self.download_url = os.getenv("URL", "null")
        self.organization = os.getenv("ORGANIZATION", "jenkins.io")
        self.product_name = os.getenv("PRODUCTNAME", "Jenkins")
        self.distribution = os.getenv("OS_FAMILY", "debian")
        self.gpg_pub_key_info_file = os.getenv("GPGPUBKEYINFO", ".")
        self.target_directory = "./target/" + self.distribution

        try:
            opts, args = getopt.getopt(
                argv, "hd:o:", ["targetDir=", "distribution=", "gpg-key-info-file="]
            )
        except getopt.GetoptError:
            print(self.HELP_MESSAGE)
            sys.exit(2)
        for opt, arg in opts:
            if opt == "-h":
                print(self.HELP_MESSAGE)
                sys.exit()
            elif opt in ("-d", "--distribution"):
                self.distribution = arg
                self.target_directory = "./target/" + self.distribution
                os.makedirs(self.target_directory, exist_ok=True)
            elif opt in ("-g", "--gpg-key-info-file"):
                self.gpg_pub_key_info_file = arg
            elif opt in ("-o", "--targetDir"):
                self.target_directory = arg
                self.targetFile = self.target_directory + "/HEADER.html"

        self.targetFile = self.target_directory + "/HEADER.html"
        self.footer = self.target_directory + "/FOOTER.html"
        self.index = self.target_directory + "/index.html"
        self.template_file = self.DISTRIBUTIONS[self.distribution]["template"]
        self.root_dir = os.path.dirname(self.target_directory[0:-1])
        self.root_header = self.root_dir + "/HEADER.html"
        self.root_footer = self.root_dir + "/FOOTER.html"
        self.web_url = self.DISTRIBUTIONS[self.distribution]["web_url"]

    def show_information(self):
        print("Product Name: " + self.product_name)
        print("Download URL: " + self.download_url)
        print("Organization: " + self.organization)
        print("Artifact Name: " + self.artifact)
        print("Distribution: " + self.distribution)
        print("Web URL: " + str(self.web_url))
        print("Number of Packages found: " + str(len(self.packages)))
        print("Template file: " + self.template_file)
        print("Repository header generated: " + self.targetFile)
        print("Repository index generated: " + self.index)
        print("Repository footer generated: " + self.footer)
        print("Root header generated: " + self.root_header)
        print("Root footer generated: " + self.root_footer)
        print("GPG Key Info File: " + self.gpg_pub_key_info_file)

    def generate_root_header(self):

        contexts = {
            "product_name": self.product_name,
            "repositories": self.repositories,
        }

        env = jinja2.Environment(
            loader=jinja2.FileSystemLoader(self.template_directory)
        )
        template = env.get_template("header.root.html")

        with open(self.root_header, "w") as f:
            f.write(template.render(contexts))

    def generate_root_footer(self):

        contexts = {}

        env = jinja2.Environment(
            loader=jinja2.FileSystemLoader(self.template_directory)
        )
        template = env.get_template("footer.html")

        with open(self.root_footer, "w") as f:
            f.write(template.render(contexts))

    def generate_footer(self):

        contexts = {"product_name": self.product_name}

        env = jinja2.Environment(
            loader=jinja2.FileSystemLoader(self.template_directory)
        )
        template = env.get_template("footer.html")

        with open(self.footer, "w") as f:
            f.write(template.render(contexts))

    def fetch_pubkeyinfo(self):
        pub_key_info = ""

        if self.gpg_pub_key_info_file != ".":
            gpg_pub_key = pathlib.Path(self.gpg_pub_key_info_file)
            if gpg_pub_key.is_file():
                with open(self.gpg_pub_key_info_file, "r") as gpg_pub_key:
                    pub_key_info = gpg_pub_key.read()

        return pub_key_info

    def generate_repository_header(self):
        contexts = {
            "product_name": self.product_name,
            "url": self.download_url,
            "organization": self.organization,
            "artifactName": self.artifact,
            "os_family": self.distribution,
            "packages": self.packages,
            "releaseline": self.releaseline,
            "web_url": self.web_url,
            "pub_key_info": self.fetch_pubkeyinfo(),
        }

        env = jinja2.Environment(
            loader=jinja2.FileSystemLoader(self.template_directory)
        )
        env.filters["basename"] = basename
        template = env.get_template(self.template_file)

        with open(self.targetFile, "w") as f:
            f.write(template.render(contexts))

    def generate_repository_index(self):
        contexts = {
            "header": self.template_file,
            "product_name": self.product_name,
            "url": self.download_url,
            "organization": self.organization,
            "artifactName": self.artifact,
            "os_family": self.distribution,
            "packages": self.packages,
            "releaseline": self.releaseline,
            "web_url": self.web_url,
            "pub_key_info": self.fetch_pubkeyinfo(),
        }

        env = jinja2.Environment(
            loader=jinja2.FileSystemLoader(self.template_directory)
        )
        env.filters["basename"] = basename
        templateIndex = env.get_template("index.html")

        with open(self.index, "w") as f:
            f.write(templateIndex.render(contexts))


if __name__ == "__main__":
    headerGenerator = IndexGenerator(sys.argv[1:])
    headerGenerator.show_information()
    headerGenerator.generate_repository_header()
    headerGenerator.generate_footer()
    headerGenerator.generate_repository_index()
    headerGenerator.generate_root_header()
    headerGenerator.generate_root_footer()
