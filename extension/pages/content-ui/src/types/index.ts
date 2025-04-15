export interface PropertyData {
    price: number;
    listingId: string;
    propertyHoa?: number;
    address?: string;
    bedrooms?: number;
    bathrooms?: number;
    squareFeet?: number;
    [key: string]: any;
  }
  
  export interface CashflowResult {
    netOperatingIncome: number;
    isPositive: boolean;
    monthlyPayment: number;
    vacancy: number;
    propertyTax: number;
    insurance: number;
    maintenance: number;
    hoaFee: number;
    managementFee: number;
    totalExpenses: number;
    rent: number;
  }
  