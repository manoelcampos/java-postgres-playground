package com.example.financeiro.yahoofinance;

public class Meta {
    private String currency;
    private double regularMarketPrice;

    public String getCurrency() {
        return currency;
    }
    public void setCurrency(String currency) {
        this.currency = currency;
    }
    public double getRegularMarketPrice() {
        return regularMarketPrice;
    }
    public void setRegularMarketPrice(double regularMarketPrice) {
        this.regularMarketPrice = regularMarketPrice;
    }
}
