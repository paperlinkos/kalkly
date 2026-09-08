// Currency Exchange Service with API fetching and offline caching

export interface CurrencyItem {
  code: string;
  name: string;
  symbol: string;
  flag: string;
}

export const SUPPORTED_CURRENCIES: CurrencyItem[] = [
  { code: 'USD', name: 'US Dollar', symbol: '$', flag: '🇺🇸' },
  { code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺' },
  { code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧' },
  { code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵' },
  { code: 'CAD', name: 'Canadian Dollar', symbol: 'CA$', flag: '🇨🇦' },
  { code: 'AUD', name: 'Australian Dollar', symbol: 'A$', flag: '🇦🇺' },
  { code: 'CHF', name: 'Swiss Franc', symbol: 'CHF', flag: '🇨🇭' },
  { code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳' },
  { code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳' },
  { code: 'NGN', name: 'Nigerian Naira', symbol: '₦', flag: '🇳🇬' },
  { code: 'BRL', name: 'Brazilian Real', symbol: 'R$', flag: '🇧🇷' },
  { code: 'MXN', name: 'Mexican Peso', symbol: 'MX$', flag: '🇲🇽' },
  { code: 'SGD', name: 'Singapore Dollar', symbol: 'S$', flag: '🇸🇬' },
  { code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK$', flag: '🇭🇰' },
  { code: 'SEK', name: 'Swedish Krona', symbol: 'kr', flag: '🇸🇪' },
  { code: 'KRW', name: 'South Korean Won', symbol: '₩', flag: '🇰🇷' },
  { code: 'AED', name: 'UAE Dirham', symbol: 'AED', flag: '🇦🇪' },
  { code: 'ZAR', name: 'South African Rand', symbol: 'R', flag: '🇿🇦' }
];

// Fallback rates relative to USD if offline and no cache exists
const DEFAULT_RATES: Record<string, number> = {
  USD: 1,
  EUR: 0.92,
  GBP: 0.78,
  JPY: 154.5,
  CAD: 1.36,
  AUD: 1.52,
  CHF: 0.90,
  CNY: 7.23,
  INR: 83.4,
  NGN: 1485.0,
  BRL: 5.15,
  MXN: 16.7,
  SGD: 1.35,
  HKD: 7.82,
  SEK: 10.8,
  KRW: 1370.0,
  AED: 3.67,
  ZAR: 18.5
};

const CACHE_KEY = 'KALKLY_CURRENCY_RATES';
const TIMESTAMP_KEY = 'KALKLY_RATES_TIMESTAMP';

export class CurrencyService {
  private rates: Record<string, number> = { ...DEFAULT_RATES };
  private lastUpdated: string = 'Offline / Default';
  private spreadPercentage: number = 0.5; // 0.5% interbank spread demo

  constructor() {
    this.loadCachedRates();
    this.fetchLatestRates();
  }

  private loadCachedRates() {
    try {
      const cached = localStorage.getItem(CACHE_KEY);
      const time = localStorage.getItem(TIMESTAMP_KEY);
      if (cached) {
        this.rates = { ...DEFAULT_RATES, ...JSON.parse(cached) };
      }
      if (time) {
        this.lastUpdated = time;
      }
    } catch {
      // Use defaults
    }
  }

  public async fetchLatestRates(): Promise<boolean> {
    try {
      const res = await fetch('https://open.er-api.com/v6/latest/USD');
      if (!res.ok) throw new Error('API response not ok');
      const data = await res.json();
      if (data && data.rates) {
        this.rates = { ...DEFAULT_RATES, ...data.rates };
        const timeStr = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        this.lastUpdated = `Live ${timeStr}`;
        localStorage.setItem(CACHE_KEY, JSON.stringify(this.rates));
        localStorage.setItem(TIMESTAMP_KEY, this.lastUpdated);
        return true;
      }
    } catch {
      // Offline fallback
    }
    return false;
  }

  public getRate(fromCurrency: string, toCurrency: string): number {
    const fromUsd = this.rates[fromCurrency] || DEFAULT_RATES[fromCurrency] || 1;
    const toUsd = this.rates[toCurrency] || DEFAULT_RATES[toCurrency] || 1;
    return toUsd / fromUsd;
  }

  public convert(amount: number, fromCurrency: string, toCurrency: string): {
    converted: number;
    rate: number;
    buyRate: number;
    sellRate: number;
  } {
    const baseRate = this.getRate(fromCurrency, toCurrency);
    const converted = amount * baseRate;
    const spreadMultiplier = this.spreadPercentage / 100;
    const buyRate = baseRate * (1 - spreadMultiplier);
    const sellRate = baseRate * (1 + spreadMultiplier);

    return {
      converted,
      rate: baseRate,
      buyRate,
      sellRate
    };
  }

  public getLastUpdated(): string {
    return this.lastUpdated;
  }
}

export const currencyService = new CurrencyService();
