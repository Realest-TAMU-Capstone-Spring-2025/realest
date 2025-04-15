// content/sites/redfin.ts
import { RealEstateSite, PropertyData, extractPrice } from './index';

class RedfinSiteImpl implements RealEstateSite {
  name = 'Redfin';

  async extractPropertyData(): Promise<PropertyData | null> {
    try {
      // Extract price
      const priceElement = document.querySelector('.price') ||
                          document.querySelector('.statsValue');
      if (!priceElement) return null;
      
      const priceText = priceElement.textContent?.trim() || '';
      const price = extractPrice(priceText);
      
      // Extract listing ID from URL
      const listingId = this.extractListingId(window.location.href);
      
      // Extract HOA fee
      const hoaFee = this.extractHoaFee();
      
      // Extract basic property details
      const bedrooms = this.extractBedrooms();
      const bathrooms = this.extractBathrooms();
      const squareFeet = this.extractSquareFeet();
      
      return {
        price,
        listingId,
        propertyHoa: hoaFee,
        bedrooms,
        bathrooms,
        squareFeet
      };
    } catch (error) {
      console.error('Error extracting Redfin property data:', error);
      return null;
    }
  }

  findWidgetLocation(): HTMLElement | null {
    try {
      // Find the price element
      const priceElement = document.querySelector('.price') ||
                          document.querySelector('.statsValue');
      
      if (!priceElement) return null;
      
      // Find a suitable container
      const container = priceElement.closest('.info-block') ||
                       priceElement.closest('.HomeInfo') ||
                       priceElement.parentElement?.parentElement;
      
      if (!container) return null;
      
      // Create a container for our widget
      const widgetContainer = document.createElement('div');
      widgetContainer.id = 'realest-cashflow-widget';
      widgetContainer.className = 'mt-4 cashflow-widget-container';
      
      // Insert after the container
      container.insertAdjacentElement('afterend', widgetContainer);
      
      return widgetContainer;
    } catch (error) {
      console.error('Error finding widget location on Redfin:', error);
      return null;
    }
  }

  private extractListingId(url: string): string {
    // Extract property ID from URL
    const idMatch = url.match(/\/(\d+)-[a-z0-9-]+\/home\/(\d+)/);
    if (idMatch && idMatch[2]) {
      return `redfin_${idMatch[2]}`;
    }
    
    // Fallback to using pathname
    const urlObj = new URL(url);
    return `redfin_${urlObj.pathname.replace(/\//g, '_')}`;
  }

  private extractHoaFee(): number {
    try {
      // Look for HOA fee in the DOM
      const hoaElements = Array.from(document.querySelectorAll('.FeeSummary div, .keyDetail')).filter(
        el => el.textContent?.includes('HOA')
      );
      
      if (hoaElements.length === 0) return 0;
      
      const hoaElement = hoaElements[0];
      const hoaText = hoaElement.textContent || '';
      const matches = hoaText.match(/\$?([\d,]+)/);
      
      if (!matches || !matches[1]) return 0;
      
      return parseInt(matches[1].replace(/,/g, ''), 10);
    } catch (error) {
      console.error('Error extracting HOA fee:', error);
      return 0;
    }
  }

  private extractBedrooms(): number {
    try {
      const bedroomsElement = document.querySelector('[data-rf-test-id="abp-beds"] .statsValue');
      if (bedroomsElement) {
        return parseInt(bedroomsElement.textContent?.trim() || '0', 10);
      }
      return 0;
    } catch (error) {
      return 0;
    }
  }

  private extractBathrooms(): number {
    try {
      const bathroomsElement = document.querySelector('[data-rf-test-id="abp-baths"] .statsValue');
      if (bathroomsElement) {
        return parseFloat(bathroomsElement.textContent?.trim() || '0');
      }
      return 0;
    } catch (error) {
      return 0;
    }
  }

  private extractSquareFeet(): number {
    try {
      const sqftElement = document.querySelector('[data-rf-test-id="abp-sqFt"] .statsValue');
      if (sqftElement) {
        const sqftText = sqftElement.textContent?.trim() || '0';
        return parseInt(sqftText.replace(/[^0-9]/g, ''), 10);
      }
      return 0;
    } catch (error) {
      return 0;
    }
  }
}

const RedfinSite = new RedfinSiteImpl();
export default RedfinSite;