package com.example.financeiro.currency;

import java.util.List;
import java.util.NoSuchElementException;

public class CurrencyAPI {
    private static List<Currency> currencyList = 
        List.of(
            new Currency("USD", "BRL", 4.96),
            new Currency("EUR", "BRL", 5.41),
            new Currency("BRL", "EUR", 0.18)
        );

    public static double getQuote(String from, String to){
        for (var currency : currencyList) {
            if(currency.getFrom().equals(from) && currency.getTo().equals(to)){
                return currency.getQuote();
            }
        }

        throw new NoSuchElementException("Nao foi encontrada uma quotacao para o par de moedas indicado");
    }
}
