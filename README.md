# WA Development Assessment Panels

This scrapes:
[Home](https://www.planning.wa.gov.au/) >>
[Current Development Assessment Panel applications and information ](https://www.planning.wa.gov.au/development-assessment-panels/current-development-assessment-panels-applications-and-information) >>
Current DAP Applications: [Pdf Download Link](https://www.planning.wa.gov.au/docs/default-source/daps-docs-website/current-applications.pdf)


This is a scraper that runs on [Morph](https://morph.io). To get started [see the documentation](https://morph.io/documentation)

Add any issues to https://github.com/planningalerts-scrapers/issues/issues

## Development Requirements

### Install pdftoxml

**MacOS**

* Homebrew: Run `brew install pdftohtml`
* MacPorts: Run `sudo port install pdftohtml` 

**Linux** (Ubuntu/Debian)

Install poppler-utils by running:

    sudo apt-get install poppler-utils


## To run the scraper

    bundle exec ruby scraper.rb

### Expected output

    Retrieving https://www.planning.wa.gov.au/docs/default-source/daps-docs-website/current-applications.pdf ...
    Running pdftohtml to convert pdf to xml pages...
    Page-1
    ...
    Page-8
    Parsing XML document ...
    Processing page# 1
    Page header: Development Assessment Panels
    Page header: All Current Applications
    Page header: Report Version 0.105.4
    Section: DAP Panel: Metro Inner DAP
    Section: LG Name: City of Bayswater
    Saving DAP/26/03060 - Lots 41-48 (290-304) Whatley Crescent, Maylands, WA
    Saving DAP/23/02575 - Lot 130 (319) and Lot 131 (321) Guildford Road, Bayswater, WA
    Section: LG Name: City of Belmont
    ...
    Processing page# 8
    ...
    Section: LG Name: Shire of York
    Saving DP/14/00039 - Lots 4869, 5931, 9926 and 26934 Great Southern Highway, St Ronans, WA
    Finished! Processed 99 records.

Execution time ~ 5 seconds

## To run style and coding checks

    bundle exec rubocop

## To check for security updates

    gem install bundler-audit
    bundle-audit

## Development

Set:

* `DEBUG=1` - to enable debug output from scraper

