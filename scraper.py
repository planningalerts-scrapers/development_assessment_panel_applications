from datetime import date
from functools import partial
from shutil import which
from typing import List, Optional
from urllib.error import HTTPError

import pandas as pd
import tabula
from selenium.webdriver import ChromeOptions
from splinter import Browser
from sqlalchemy import create_engine
from tabula import read_pdf

# Note: work-around because the morph early_release image doesn't have java installed,
# and the tabula _run() function has the java path hard-coded
if which("java") is None:
    print("Java not found. Installing JRE.")
    import jdk
    import tabula_custom
    jre_dir = jdk.install('11', jre=True, path='/tmp/.jre')
    tabula.io._run = partial(tabula_custom._run, java_path=jre_dir + '/bin/java')

URL = "https://www.wa.gov.au/organisation/department-of-planning-lands-and-heritage/current-development-assessment-panel-applications-and-information"
DATABASE = "data.sqlite"
DATA_TABLE = "data"
PROCESSED_FILES_TABLE = "files_processed"
PROCESSED_FILES_COLUMN = "name"

engine = create_engine(f'sqlite:///{DATABASE}', echo=False)
pd.DataFrame(columns=[PROCESSED_FILES_COLUMN]).to_sql(PROCESSED_FILES_TABLE, con=engine, if_exists="append")


def clean_received_date(dmy: str) -> Optional[date]:
    if dmy == '':
        return None
    d, m, y = dmy.replace(' ', '').split("/")
    if len(y) == 2:
        y = f"20{y}"
    return date(int(y), int(m), int(d))


def clean_address(address: str) -> str:
    """
    :param address: as extracted from PDF, containing line breaks, e.g. Lots 54 and 55 (92-94) Wanneroo Road,\rYokine
    :return: cleaned address, optimised for address parsing, e.g. Lots 54 and 55, 92-94 Wanneroo Road, Yokine, WA
    """
    return address.replace("\r", " ") + ", WA"


def clean_description(description: str) -> str:
    return description.replace("\r", " ")

# can not use simple request to get the page content. Need headless browser
options = ChromeOptions()
options.headless = True
options.add_argument('--no-sandbox')
options.add_argument('--disable-extensions')

with Browser('chrome', headless=True, options=options) as browser:
    browser.visit(URL)
    links = browser.find_by_xpath("//a[contains(text(), 'Current DAP applications (PDF')]")
    print(f"Found {len(links)} links")
    for link in links:
        pdf_url = link["href"]
        title = pdf_url.split('/')[-1]

        if len(engine.execute(f"SELECT 1 FROM {PROCESSED_FILES_TABLE} WHERE name=:title", dict(title=title)).fetchall()) > 0:
            print(f"==== read file {title} already")
            continue

        print(f"Downloading PDF for '{title}' - {pdf_url}")
        try:
            dfs: List[pd.DataFrame] = read_pdf(pdf_url,
                                               lattice=True,
                                               pages="all",
                                               user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64)')
        except HTTPError as e:
            print(f"Failed to download url - {e} ; skipping")
            continue

        final_df = pd.DataFrame()
        for df_idx, df in enumerate(dfs):
            if df.empty:
                continue
            else:
                final_df = final_df.append(df)

        df = final_df

        # header cleanup
        df.columns = df.columns.map(lambda x: x.replace("\r", " "))

        # drop empty columns
        df.dropna(axis=1, how='all', inplace=True)
        df['DAP Panel'] = df['DAP Panel'].ffill()
        df['LG Name'] = df['LG Name'].ffill()
        df.fillna('', inplace=True)

        print(title)
        print(df.head(1))
        print(df.columns.values)

        try:
            resultTable = pd.DataFrame()
            resultTable['date_received'] = df['Date Application Received'].map(clean_received_date)
            resultTable['address'] = df['Property Location'].map(clean_address)
            resultTable['description'] = df['Application Description'].map(clean_description) \
                                         + ", Value: " + df['Form 1 Dev Cost ($ Million)']

            resultTable['council_reference'] = df['DAP Application Reference Number']
            resultTable['date_scraped'] = date.today()
            resultTable['info_url'] = pdf_url
            resultTable.to_sql(DATA_TABLE, con=engine, if_exists='append', index=False)
            print(f"Saved {len(resultTable)} records")
        except Exception as e:
            print(f"failed to process {title} - {str(e)}")
            print(df)
            raise e

        pd.DataFrame([title], columns=[PROCESSED_FILES_COLUMN]).to_sql(PROCESSED_FILES_TABLE, con=engine, if_exists="append")
