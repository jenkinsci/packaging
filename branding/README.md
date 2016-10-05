# Branding Definition
Branding definition file has the following variables

* `RELEASELINE`: used only for OSS Jenkins releases. This variable selects one of the 4 release lines that we
  maintain (empty for mainline releases, "-rc" for RCs, "-stable" for LTS, and "-stable-rc" for LTS RCs.)
* `PRODUCTNAME`: Short human readable name of the product. Should be something like "Acme Foo Bar Zot".
  Used as the title of the product.
* `SUMMARY`: One line human readable description of what the product does.
* `ARTIFACTNAME`: Alpha-numeric lower-case (plus '-' and '_') only machine name of the product. Used as the stem of the file names.
* `CAMELARTIFACTNAME`: Alpha-numeric machine name of the product, but in CamelCase (such as FooBarZot.)
  By convention this name should not have '-' or '_'
* `VENDOR`: Short human readable name of the entity that generates the package.
* `PORT`: TCP/IP port that Jenkins will bind to out of the box.
* `MSI_PRODUCTCODE`: Windows installer uses UUID to identify which MSI files are of the same lineage.
  If two MSIs have the same UUID, one will overwrite another. So if you are to produce your own MSI,
  you need to use a different UUID.
* `OSX_IDPREFIX`: prefix of the various IDs in OS X. This follows the reverse domain name format.
* `AUTHOR`: Author name & email for distributed package, i.e. Bob Smith <nobody@example.com>
* `LICENSE`: License(s) for this distribution, such as 'Apache 2.0'
* `HOMEPAGE`: homepage URL for this distribution of Jenkins (where users should go for more information)
* `CHANGELOG_PAGE`: URL that users should visit to see the changelog for this distribution of Jenkins

# Branding Files
Each of these is an (absolute) path to a file containing a larger blob of brand-specific information.
The file is read to the environment variable, and then templated in as with the variables above

* `DESCRIPTION_FILE`: path to file containing the RPM description section (see 'description-file' in branding for an example)
* `DESCRIPTION_FILE_DEB`: path to file containing the Debian description section (see 'description-file-deb' in branding for an example).  This should be the same as the DESCRIPTION FILE, just following Debian packaging convention.

# Special handling:

License files are handled specially:
* `LICENSE_FILE` is the path of a file containing the license/copyright text body

This is transformed specially (by setup.mk) for use in branding each different package:

* `LICENSE_TEXT` is the actual file contents
* `LICENSE_TEXT_COMMENTED` is the license text, split to 80 character lines with #-style comment at the start of each line
* `LICENSE_TEXT_DEB` is formatted for a Debian copyright file, with a . between each paragraph, and one whitespace before each line