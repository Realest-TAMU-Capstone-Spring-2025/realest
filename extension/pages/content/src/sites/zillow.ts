import { RealEstateSite, PropertyData, extractPrice } from './index';

class ZillowSiteImpl implements RealEstateSite {
  name = 'Zillow';

  async extractPropertyData(): Promise<PropertyData | null> {
    try {
      // Extract price from Zillow DOM
      const priceElement = document.querySelector('[data-testid="price"]');
      if (!priceElement) return null;
      
      const priceText = priceElement.textContent?.trim() || '';
      const price = extractPrice(priceText);
      
      // Extract listing ID from URL
      const listingId = this.extractListingId(window.location.href);
      
      // Extract bedrooms, bathrooms, sqft
      const bedBathItems = document.querySelectorAll('[data-testid="bed-bath-item"]');
      let bedrooms = 0;
      let bathrooms = 0;
      let squareFeet = 0;
      
      bedBathItems.forEach((item, index) => {
        const text = item.textContent || '';
        if (index === 0 && text.includes('bd')) {
          bedrooms = parseInt(text.replace(/[^0-9]/g, ''), 10);
        } else if (index === 1 && text.includes('ba')) {
          bathrooms = parseFloat(text.replace(/[^0-9.]/g, ''));
        } else if (index === 2 && text.includes('sqft')) {
          squareFeet = parseInt(text.replace(/[^0-9]/g, ''), 10);
        }
      });
      
      // Extract HOA fee if available
      const hoaFee = this.extractHoaFee();
      
      // Extract address
      const addressElement = document.querySelector('h1');
      const address = addressElement?.textContent?.trim() || '';

      const rent = this.extractRent();
      
      return {
        price,
        listingId,
        rent,
        propertyHoa: hoaFee,
        address,
        bedrooms,
        bathrooms,
        squareFeet
      };
    } catch (error) {
      console.error('Error extracting Zillow property data:', error);
      return null;
    }
  }
  findWidgetLocation(): HTMLElement | null {
    try {
      // Find the price element
      const priceElement = document.querySelector('[data-testid="price"]');
      if (!priceElement) return null;
      
      // Create a container for our button that will be placed inline with the price
      // Create a container for our button
      const buttonContainer = document.createElement('span');
      buttonContainer.id = 'realest-cashflow-button-container';
      buttonContainer.style.cssText = `
        margin-left: 8px;
        display: inline-flex;
        align-items: center; /* This centers the button vertically */
        vertical-align: middle; /* Aligns with the text baseline */
      `;

      // buttonContainer.className = 'ml-2 inline-block'; // Add margin-left for spacing
      
      // Insert the button container right after the price span
      const priceSpan = priceElement.querySelector('span');
      if (priceSpan) {
        // Insert after the inner span that contains the price text
        priceSpan.insertAdjacentElement('afterend', buttonContainer);
        
        // Set up a MutationObserver to detect if our button gets removed
        const observer = new MutationObserver((mutations) => {
          // Check if our button was removed
          if (!document.getElementById('realest-cashflow-widget')) {
            // Re-insert the button
            const updatedPriceElement = document.querySelector('[data-testid="price"]');
            const updatedPriceSpan = updatedPriceElement?.querySelector('span');
            if (updatedPriceSpan && !updatedPriceSpan.nextElementSibling?.id?.includes('realest-cashflow')) {
              updatedPriceSpan.insertAdjacentElement('afterend', buttonContainer);
            }
          }
        });
        
        // Start observing the price element and its children
        observer.observe(priceElement.parentElement || document.body, {
          childList: true,
          subtree: true
        });
      } else {
        // Fallback: append to the price element itself
        priceElement.appendChild(buttonContainer);
      }
      
      return buttonContainer;
    } catch (error) {
      console.error('Error finding widget location on Zillow:', error);
      return null;
    }
  }
  private extractListingId(url: string): string {
    // Extract zpid from URL
    const zpidMatch = url.match(/_zpid\/(\d+)_/) || url.match(/\/(\d+)_zpid/);
    if (zpidMatch && zpidMatch[1]) {
      return `zillow_${zpidMatch[1]}`;
    }
    
    // Fallback to using pathname as ID
    const urlObj = new URL(url);
    return `zillow_${urlObj.pathname.replace(/\//g, '_')}`;
  }
  private extractHoaFee(): number {
    try {
      // Look for elements containing HOA text
      const hoaElements = Array.from(document.querySelectorAll('span')).filter(
        el => el.textContent?.includes('HOA')
      );
      
      if (hoaElements.length === 0) return 0;
      
      // For each HOA element, try to extract the fee
      for (const hoaElement of hoaElements) {
        const hoaText = hoaElement.textContent || '';
        
        // Match pattern like "$2/mo HOA" or "HOA: $150"
        const matches = hoaText.match(/\$?([\d,]+)(?:\/mo)?(?:\s+HOA|$)/i) || 
                        hoaText.match(/HOA[:\s]+\$?([\d,]+)/i);
        
        if (matches && matches[1]) {
          return parseInt(matches[1].replace(/,/g, ''), 10);
        }
        
        // If not found in the element itself, check next sibling as fallback
        const siblingText = hoaElement.nextElementSibling?.textContent || '';
        const siblingMatches = siblingText.match(/\$?([\d,]+)/);
        
        if (siblingMatches && siblingMatches[1]) {
          return parseInt(siblingMatches[1].replace(/,/g, ''), 10);
        }
      }
      
      return 0;
    } catch (error) {
      console.error('Error extracting HOA fee:', error);
      return 0;
    }
  }
  private extractRent(): number {
    try {
      // Look for the rent Zestimate element using the data-testid attribute
      const rentElement = document.querySelector('[data-testid="rent-zestimate"]');
      if (!rentElement) return 0;
      
      // Extract the text content from the element
      const rentText = rentElement.textContent || '';
      
      // Use regex to extract the numeric portion
      // This pattern matches a dollar sign followed by digits and commas, optionally followed by /mo
      const matches = rentText.match(/\$?([\d,]+)(?:\/mo)?/);
      
      if (!matches || !matches[1]) return 0;
      
      // Parse the matched string into a number, removing any commas
      return parseInt(matches[1].replace(/,/g, ''), 10);
    } catch (error) {
      console.error('Error extracting rent Zestimate:', error);
      return 0;
    }
  }
}

const ZillowSite = new ZillowSiteImpl();
export default ZillowSite;