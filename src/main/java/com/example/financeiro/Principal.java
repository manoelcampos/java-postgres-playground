package com.example.financeiro;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse.BodyHandlers;

import com.example.financeiro.currency.CurrencyAPI;
import com.example.financeiro.dao.TransacaoDAO;
import com.example.financeiro.model.Transacao;
import com.example.financeiro.yahoofinance.YahooFinanceData;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.json.JsonMapper;

public class Principal {
    private static final String ADDRESS = "https://query1.finance.yahoo.com/v7/finance/spark?symbols=USDBRL=X";

    public static void main(String[] args) {
        simulatedAPIReqeust();
        yahooFinanceRequest();

        var dao = new TransacaoDAO();
        dao.adicionar(new Transacao("Manoel", 100, "USD", 'D'));
        dao.adicionar(new Transacao("Manoel", 100, "BRL", 'D'));
        dao.adicionar(new Transacao("Manoel", 10, "BRL", 'T'));
        dao.adicionar(new Transacao("Manoel", 20, "BRL", 'D'));
        var ultima = new Transacao("Manoel", 5,   "BRL", 'R');
        dao.adicionar(ultima);

        //Transacao.getLista().forEach(System.out::println);
        System.out.println("Saldo: " + dao.getSaldo("Manoel"));
    }

    private static void simulatedAPIReqeust() {
        System.out.println(CurrencyAPI.getQuote("BRL",  "EUR"));
    }

    private static void yahooFinanceRequest() {
        var http = HttpClient.newHttpClient();
        try {
            var mapper = new JsonMapper()
                            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
            var req = HttpRequest.newBuilder(new URI(ADDRESS)).GET().build();
            var resp = http.send(req, BodyHandlers.ofString());

            var yahooFinanceData = mapper.readValue(resp.body(), YahooFinanceData.class);
            var result = yahooFinanceData.getSpark().getResult()[0];
            System.out.println(result.getResponse()[0].getMeta().getRegularMarketPrice());
        } catch (URISyntaxException e) {
            System.err.println("Endereco da API invalido");
        } catch (IOException | InterruptedException e) {
            System.err.println("Ocorreu um erro ao enviar requisicao à API");
            e.printStackTrace();
        }
    }
}
