// content/sites/index.ts
import ZillowSite from './zillow';
import RedfinSite from './redfin';

export interface PropertyData {
    price: number;
    rent: number | null;
    listingId: string;
    propertyHoa?: number;
    address?: string;
    bedrooms?: number;
    bathrooms?: number;
    squareFeet?: number;
  }
  
export interface RealEstateSite {
  name: string;
  extractPropertyData: () => Promise<PropertyData | null>;
  findWidgetLocation: () => HTMLElement | null;
}

export const detectSite = (url: string): RealEstateSite | null => {
  if (url.includes('zillow.com')) {
    return ZillowSite;
  } else if (url.includes('redfin.com')) {
    return RedfinSite;
  }
  return null;
};
  
// Helper function to extract price from text
export const extractPrice = (priceText: string): number => {
  if (!priceText) return 0;
  const matches = priceText.match(/\$?([\d,]+)/);
  if (!matches || !matches[1]) return 0;
  return parseInt(matches[1].replace(/,/g, ''), 10);
};
