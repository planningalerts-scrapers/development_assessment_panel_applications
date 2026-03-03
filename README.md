# WA Development Assessment Panels

This scrapes:
[Home](https://www.planning.wa.gov.au/) >>
[Current Development Assessment Panel applications and information ](https://www.planning.wa.gov.au/development-assessment-panels/current-development-assessment-panels-applications-and-information) >>
Current DAP Applications: [Pdf Download Link](https://www.planning.wa.gov.au/docs/default-source/daps-docs-website/current-applications.pdf?sfvrsn=ebbf7a78_244)


This is a scraper that runs on [Morph](https://morph.io). To get started [see the documentation](https://morph.io/documentation)

Add any issues to https://github.com/planningalerts-scrapers/issues/issues

## Requirements

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

Execution time ~ 1 minute (per authority)

## To run style and coding checks

    bundle exec rubocop

## To check for security updates

    gem install bundler-audit
    bundle-audit

## Development

Set:

* `DEBUG=1` - to enable debug output from scraper

