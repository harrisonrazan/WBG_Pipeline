import json
import logging
import time
import asyncio
import pandas as pd
from bs4 import BeautifulSoup
from pyppeteer import launch
from tqdm import tqdm
import os
import multiprocessing
from concurrent.futures import ProcessPoolExecutor
import math
import atexit
import signal
import sys

# Set up logger
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

# Constants
MAX_CONCURRENT_BROWSERS = 2  # Reduced from 10 for better stability
BROWSER_TIMEOUT = 30  # seconds
CACHE_DIR = "wb_html_cache"  # Directory to cache HTML content
BATCH_SIZE = 5  # Process URLs in batches of this size

# Global state management
class GlobalState:
    def __init__(self):
        self.active_browsers = []
        self.event_loop = None

global_state = GlobalState()

# Improved cleanup handlers
async def async_cleanup_browsers():
    """Asynchronously close all active browser instances."""
    if not global_state.active_browsers:
        return
        
    logger.info(f"Cleaning up {len(global_state.active_browsers)} active browser instances")
    cleanup_tasks = []
    
    for browser in global_state.active_browsers:
        try:
            if browser and not browser.process.returncode:
                cleanup_tasks.append(browser.close())
        except Exception as e:
            logger.error(f"Error preparing browser cleanup: {str(e)}")
    
    if cleanup_tasks:
        await asyncio.gather(*cleanup_tasks, return_exceptions=True)
    
    global_state.active_browsers.clear()

def cleanup_browsers():
    """Synchronous wrapper for browser cleanup."""
    if not global_state.active_browsers:
        return
        
    # Create a new event loop if needed
    try:
        loop = asyncio.get_event_loop()
        if loop.is_closed():
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
        loop.run_until_complete(async_cleanup_browsers())
    except Exception as e:
        logger.error(f"Error in cleanup: {str(e)}")
        # Last resort: terminate processes directly
        for browser in global_state.active_browsers:
            try:
                if hasattr(browser, 'process') and browser.process:
                    browser.process.terminate()
            except:
                pass
        global_state.active_browsers.clear()

# Register the cleanup function
atexit.register(cleanup_browsers)

# Handle signals for graceful termination
def signal_handler(sig, frame):
    """Handle termination signals by cleaning up browsers first."""
    logger.info(f"Received signal {sig}, cleaning up...")
    cleanup_browsers()
    sys.exit(0)

# Register signal handlers
signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

async def fetch_with_pyppeteer(url, semaphore, timeout=45, retries=3):
    """Docker-optimized function to fetch URL content using pyppeteer."""
    async with semaphore:
        for attempt in range(retries):
            browser = None
            try:
                # Docker-optimized launch settings
                browser = await launch(
                    headless=True, 
                    args=[
                        '--no-sandbox',
                        '--disable-setuid-sandbox',
                        '--disable-dev-shm-usage',
                        '--disable-accelerated-2d-canvas',
                        '--disable-gpu',
                        '--disable-extensions',
                        '--disable-component-extensions-with-background-pages',
                        '--disable-default-apps',
                        '--mute-audio',
                        '--single-process',  # Try single process mode
                        '--disable-background-networking',
                        '--disable-background-timer-throttling',
                        '--disable-backgrounding-occluded-windows',
                        '--disable-breakpad',
                        '--disable-client-side-phishing-detection',
                        '--disable-hang-monitor',
                        '--disable-prompt-on-repost',
                        '--disable-sync',
                        '--disable-translate',
                        '--metrics-recording-only',
                        '--no-first-run',
                        '--safebrowsing-disable-auto-update',
                    ],
                    ignoreHTTPSErrors=True,
                    executablePath='/usr/bin/chromium' if os.path.exists('/usr/bin/chromium') else None
                )
                
                global_state.active_browsers.append(browser)
          
                # Minimal page setup
                page = await browser.newPage()
                await page.setViewport({'width': 800, 'height': 600})  # Smaller viewport
                
                # Aggressive request blocking to reduce resource usage
                await page.setRequestInterception(True)
                async def intercept_request(req):
                    if req.resourceType in ['document', 'xhr']:
                        await req.continue_()
                    else:
                        await req.abort()
                
                page.on('request', lambda req: asyncio.ensure_future(intercept_request(req)))
             
                # Use domcontentloaded instead of networkidle0 for faster loading
                response = await page.goto(url, {
                    'timeout': timeout * 1000, 
                    'waitUntil': 'domcontentloaded'
                })
                
                if not response or response.status != 200:
                    logger.warning(f"Received status {response.status if response else 'none'} for {url}")
                    if attempt < retries - 1:
                        await browser.close()
                        if browser in global_state.active_browsers:
                            global_state.active_browsers.remove(browser)
                        browser = None
                        await asyncio.sleep(2 ** attempt)
                        continue
                
                # Simplified wait - don't fail if selector not found
                try:
                    await page.waitForSelector('.main-detail', {'timeout': 10000})  # Reduced timeout
                except Exception as e:
                    logger.warning(f"Element .main-detail not found on {url}, continuing anyway")
                
                # Get content and close browser
                content = await page.content()
                
                await browser.close()
                if browser in global_state.active_browsers:
                    global_state.active_browsers.remove(browser)
                browser = None
                
                return content
               
            except Exception as e:
                logger.warning(f"Attempt {attempt+1}/{retries} failed for {url}: {str(e)}")
                
                if browser:
                    try:
                        await browser.close()
                    except Exception as close_error:
                        logger.error(f"Error closing browser: {str(close_error)}")
                    finally:
                        if browser in global_state.active_browsers:
                            global_state.active_browsers.remove(browser)
                
                if attempt < retries - 1:
                    await asyncio.sleep(2 ** attempt)
        
        logger.error(f"All {retries} attempts failed for {url}")
        return None

def parse_project_relationships(html, url):
    """Parse the HTML content to extract relationship data."""
    if not html:
        return {
            "url": url,
            "project_id": url.split("/")[-1],
            "parent_project": None,
           "associated_projects": []
        }
    
    result = {
        "url": url,
        "project_id": url.split("/")[-1],
        "parent_project": None,
        "associated_projects": []
    }
    
    try:
        # Parse with BeautifulSoup
        soup = BeautifulSoup(html, 'html.parser')
        
        # Find the main-detail div
        main_detail = soup.find('div', class_='main-detail')
        
        if not main_detail:
            logger.warning(f"main-detail div not found on {url} after parsing")
            return result
        
        # Find all list items within the main-detail div
        list_items = main_detail.find_all('li')
        
        # Process list items
        for li in list_items:
            item_text = li.get_text(strip=True)
            
            # Skip items that don't contain "Parent Project" or "Associated Project"
            if "Parent Project" not in item_text and "Associated Project" not in item_text:
                continue
                
            # Extract any links within the list item
            item_links = []
            for link in li.find_all('a'):
                href = link.get('href', '')
                if href and '/projects-operations/project-detail/' in href:
                    item_links.append({
                        "text": link.get_text(strip=True),
                        "url": href
                    })
            
            if not item_links:
                continue
                
            # Check if this is a parent project item
            if "Parent Project" in item_text and item_links:
                # Update the parent_project field with the first link
                result["parent_project"] = {
                    "title": item_links[0]["text"],
                    "url": item_links[0]["url"],
                    "id": item_links[0]["url"].split("/")[-1] if item_links[0]["url"] else None
                }
            
            # Check if this is an associated projects item
            elif "Associated Project" in item_text:
                # Add to associated_projects (might be multiple links)
                for link in item_links:
                    if "/projects-operations/project-detail/" in link["url"]:
                        project_data = {
                            "title": link["text"],
                            "url": link["url"],
                            "id": link["url"].split("/")[-1]
                        }
                        result["associated_projects"].append(project_data)
        
        return result
        
    except Exception as e:
        logger.error(f"Error parsing HTML for {url}: {str(e)}")
        return result

def get_cache_path(url, cache_dir=CACHE_DIR):
    """Get the cache file path for a URL."""
    project_id = url.split("/")[-1]
    return os.path.join(cache_dir, f"{project_id}.html")

def read_from_cache(url, cache_dir=CACHE_DIR):
    """Read HTML content from cache if available."""
    cache_path = get_cache_path(url, cache_dir)
    if os.path.exists(cache_path):
        try:
            with open(cache_path, 'r', encoding='utf-8') as f:
                return f.read()
        except Exception as e:
            logger.error(f"Error reading from cache for {url}: {str(e)}")
    return None

def write_to_cache(url, html, cache_dir=CACHE_DIR):
    """Write HTML content to cache."""
    if not os.path.exists(cache_dir):
        os.makedirs(cache_dir)
    
    cache_path = get_cache_path(url, cache_dir)
    try:
        with open(cache_path, 'w', encoding='utf-8') as f:
            f.write(html)
    except Exception as e:
        logger.error(f"Error writing to cache for {url}: {str(e)}")

def cleanup_cache(result, cache_dir=CACHE_DIR):
    """
    Delete cache file if parent project or associated projects are found.
    
    Args:
        result (dict): The parsed result containing project relationship data
        cache_dir (str): Directory for HTML cache
    """
    # Check if parent project or associated projects exist
    if (result.get('parent_project') or result.get('associated_projects')):
        url = result.get('url')
        cache_path = get_cache_path(url, cache_dir)
        
        if os.path.exists(cache_path):
            try:
                os.remove(cache_path)
                logger.info(f"Removed cache for {url} due to found relationships")
            except Exception as e:
                logger.error(f"Error removing cache for {url}: {str(e)}")

async def process_url(url, semaphore, use_cache=True, cache_dir=CACHE_DIR):
    """Process a single URL: fetch, cache, and parse."""
    # Format URL if needed (handle project IDs vs full URLs)
    if not url.startswith('http'):
        url = f"https://projects.worldbank.org/en/projects-operations/project-detail/{url}"
    
    # Try to read from cache first if enabled
    if use_cache:
        cached_html = read_from_cache(url, cache_dir)
        if cached_html:
            result = parse_project_relationships(cached_html, url)
            
            # If relationships found, clean up cache to force refresh next time
            cleanup_cache(result, cache_dir)
            
            return result
    
    # Fetch HTML content
    html = await fetch_with_pyppeteer(url, semaphore)
    
    # Write to cache if successful
    if html and use_cache:
        write_to_cache(url, html, cache_dir)
    
    # Parse HTML
    result = parse_project_relationships(html, url)
    
    # Clean up cache if relationships found
    if use_cache:
        cleanup_cache(result, cache_dir)
    
    # Return results
    return result

async def process_batch(urls, semaphore, use_cache=True, cache_dir=CACHE_DIR):
    """Process a batch of URLs concurrently."""
    tasks = [process_url(url, semaphore, use_cache, cache_dir) for url in urls]
    return await asyncio.gather(*tasks)

async def batch_processor(all_urls, semaphore, use_cache=True, cache_dir=CACHE_DIR, batch_size=BATCH_SIZE):
    """Process URLs in smaller batches to improve stability."""
    results = []
    
    # Process URLs in batches
    for i in range(0, len(all_urls), batch_size):
        batch = all_urls[i:i+batch_size]
        logger.info(f"Processing batch {i//batch_size + 1}/{math.ceil(len(all_urls)/batch_size)} ({len(batch)} URLs)")
        
        batch_results = await process_batch(batch, semaphore, use_cache, cache_dir)
        results.extend(batch_results)
        
        # Brief pause between batches
        await asyncio.sleep(1)
        
        # Ensure browsers are cleaned up between batches
        await async_cleanup_browsers()
        
    return results

def find_related_projects(urls):
    """Run the scraper on a list of URLs."""
    # Ensure event loop is properly managed
    try:
        loop = asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
    
    global_state.event_loop = loop
    
    semaphore = asyncio.Semaphore(MAX_CONCURRENT_BROWSERS)
    results = loop.run_until_complete(batch_processor(urls, semaphore))
    
    # Clean up browsers before returning
    loop.run_until_complete(async_cleanup_browsers())
    
    return results

def export_results_to_json(results, output_file="project_relationships.json"):
    """Export results to a JSON file."""
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2)
        logger.info(f"Results exported to {output_file}")
        return True
    except Exception as e:
        logger.error(f"Error exporting results: {str(e)}")
        return False

def export_results_to_csv(results, output_file="project_relationships.csv"):
    """Export results to a CSV file."""
    try:
        # Prepare data for CSV
        rows = []
        for result in results:
            project_id = result["project_id"]
            parent_id = result.get("parent_project", {}).get("id") if result.get("parent_project") else None
            
            # For each associated project, create a row
            if result["associated_projects"]:
                for assoc in result["associated_projects"]:
                    rows.append({
                        "project_id": project_id,
                        "parent_project_id": parent_id,
                        "associated_project_id": assoc["id"],
                        "relationship_type": "has_associated"
                    })
            else:
                # If no associated projects, still create a row
                rows.append({
                    "project_id": project_id,
                    "parent_project_id": parent_id,
                    "associated_project_id": None,
                    "relationship_type": "no_associated" if parent_id else "no_relationships"
                })
        
        # Create DataFrame and export
        df = pd.DataFrame(rows)
        df.to_csv(output_file, index=False)
        logger.info(f"Results exported to {output_file}")
        return True
    except Exception as e:
        logger.error(f"Error exporting results to CSV: {str(e)}")
        return False
    
def enrich_dataframe_with_relationships(df, url_column='project_id_url', batch_size=5, use_cache=True):
    """
    Docker-optimized function to enrich a dataframe with project relationship data.
    """
    import pandas as pd
    import json
    import time
    import random
    
    logger.info(f"Enriching {len(df)} projects with relationship data...")
    
    # Initialize columns
    if 'parent_project' not in df.columns:
        df['parent_project'] = None
    if 'associated_projects' not in df.columns:
        df['associated_projects'] = "[]"
    
    # Extract URLs - limit to a reasonable number for testing if there are many
    all_urls = []
    id_to_idx_map = {}
    
    for idx, url in enumerate(df[url_column]):
        if url and isinstance(url, str):
            project_id = url.split('/')[-1]
            all_urls.append(url)
            id_to_idx_map[project_id] = idx
    
    if not all_urls:
        logger.warning("No valid URLs found in the dataframe")
        return df
    
    # For very large datasets, consider just processing a subset first
    process_count = min(len(all_urls), 50)  # Limit for initial testing
    
    if process_count < len(all_urls):
        logger.warning(f"Processing only {process_count} out of {len(all_urls)} URLs for testing")
        # Take a random sample for testing
        sample_urls = random.sample(all_urls, process_count)
    else:
        sample_urls = all_urls
    
    # Very small batch size for Docker
    actual_batch_size = min(batch_size, 3)
    logger.info(f"Using batch size of {actual_batch_size} for processing {len(sample_urls)} URLs")
    
    # Process URLs in extremely small batches with retry mechanism
    all_results = []
    
    # Split URLs into tiny chunks
    url_chunks = [sample_urls[i:i+actual_batch_size] for i in range(0, len(sample_urls), actual_batch_size)]
    
    # Process each chunk with retry mechanism
    for chunk_idx, url_chunk in enumerate(url_chunks):
        max_retries = 3
        for retry in range(max_retries):
            try:
                logger.info(f"Processing batch {chunk_idx+1}/{len(url_chunks)} ({len(url_chunk)} URLs)")
                
                # Create a new loop for each batch to avoid event loop issues in Docker
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                
                # Use a semaphore with very limited concurrency
                semaphore = asyncio.Semaphore(1)  # Process one URL at a time
                
                # Process the batch
                chunk_results = loop.run_until_complete(batch_processor(
                    url_chunk, 
                    semaphore,
                    use_cache=use_cache,
                    batch_size=1  # Process one URL at a time
                ))
                
                # Clean up resources
                loop.run_until_complete(async_cleanup_browsers())
                loop.close()
                
                all_results.extend(chunk_results)
                
                # Success - break retry loop
                break
                
            except Exception as e:
                logger.error(f"Error processing batch {chunk_idx+1}: {str(e)}")
                if retry < max_retries - 1:
                    # Wait before retry with progressive backoff
                    wait_time = (retry + 1) * 10
                    logger.info(f"Retrying in {wait_time} seconds...")
                    time.sleep(wait_time)
                    
                    # Force cleanup
                    cleanup_browsers()
                else:
                    logger.error(f"Failed to process batch {chunk_idx+1} after {max_retries} retries")
        
        # Sleep between batches to avoid overwhelming the system
        time.sleep(5)
        
        # Every 5 batches, rest longer
        if (chunk_idx + 1) % 5 == 0:
            logger.info(f"Processed {chunk_idx+1} batches. Taking a break...")
            time.sleep(15)
    
    # Update the dataframe with results
    update_count = 0
    for result in all_results:
        project_id = result["project_id"]
        
        # Skip if we don't have this project in our mapping
        if project_id not in id_to_idx_map:
            continue
            
        idx = id_to_idx_map[project_id]
        
        # Extract parent project ID if available
        if result.get("parent_project"):
            parent_project = result["parent_project"]["id"]
            df.at[idx, 'parent_project'] = parent_project
        
        # Extract associated project IDs if available
        associated_projects = []
        if result.get("associated_projects"):
            associated_projects = [ap["id"] for ap in result["associated_projects"]]
            df.at[idx, 'associated_projects'] = json.dumps(associated_projects)
        
        update_count += 1
    
    logger.info(f"Added relationship data for {update_count} out of {len(sample_urls)} projects")
    
    return df

if __name__ == "__main__":
    import sys
    import argparse
    
    # Set up argument parser
    parser = argparse.ArgumentParser(description="World Bank Project Relationship Scraper")
    parser.add_argument("--url", help="Test a single URL")
    parser.add_argument("--file", help="Path to a file containing URLs, one per line")
    parser.add_argument("--output", default="project_relationships", help="Output file name without extension")
    parser.add_argument("--format", choices=["json", "csv", "both"], default="json", help="Output format")
    parser.add_argument("--no-cache", action="store_true", help="Disable HTML caching")
    
    args = parser.parse_args()
    
    urls_to_process = []
    
    # Collect URLs to process
    if args.url:
        urls_to_process.append(args.url)
    elif args.file:
        try:
            with open(args.file, 'r') as f:
                urls_to_process = [line.strip() for line in f if line.strip()]
        except Exception as e:
            logger.error(f"Error reading input file: {str(e)}")
            sys.exit(1)
    else:
        # Use test URLs if no input specified
        urls_to_process = [
            "https://projects.worldbank.org/en/projects-operations/project-detail/P159562",
            "https://projects.worldbank.org/en/projects-operations/project-detail/P149323",
            "https://projects.worldbank.org/en/projects-operations/project-detail/P178614",
            "https://projects.worldbank.org/en/projects-operations/project-detail/P153370"
        ]
    
    logger.info(f"Processing {len(urls_to_process)} URLs")
    
    # Run the scraper
    results = find_related_projects(urls_to_process)
    
    # Export results
    if args.format in ["json", "both"]:
        export_results_to_json(results, f"{args.output}.json")
    
    if args.format in ["csv", "both"]:
        export_results_to_csv(results, f"{args.output}.csv")
    
    # Print summary to console
    for result in results:
        print("\nResults for:", result["url"])
        print(json.dumps(result, indent=2))