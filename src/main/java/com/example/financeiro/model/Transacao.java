package com.example.financeiro.model;

import java.util.*;
import java.util.function.Predicate;
import java.util.stream.Collectors;

import com.example.financeiro.currency.CurrencyAPI;

public class Transacao {
    private static final String MOEDA_LOCAL = "BRL";

    private Integer id;
    private String cliente;
    private double valor;
    private String moeda;
    private char tipo;
    
    public Transacao(String cliente, double valor, String moeda, char tipo) {
        this.cliente = cliente;
        this.valor = valor;
        this.moeda = moeda;
        this.tipo = tipo;
    }

    private static final List<Transacao> lista = new LinkedList<>();

    public static void adicionar(Transacao t) {
        lista.add(t);
    }

    public static List<Transacao> filtrar(String cliente){
        return filtrar(transacao -> transacao.getCliente().equals(cliente));
    }
    
    public static List<Transacao> filtrar(char tipo){
        return filtrar(transacao -> transacao.getTipo() == tipo);
    }

    public static List<Transacao> filtrar(String cliente, char tipo){
        return filtrar(transacao -> transacao.getCliente().equals(cliente) && transacao.getTipo() == tipo);
    }

    private static List<Transacao> filtrar(Predicate<Transacao> predicate){
        return lista.stream().filter(predicate).collect(Collectors.toCollection(LinkedList::new));
    }

    public static double getSaldo(final String cliente) {
        final var transacoes = filtrar(cliente);

        double saldo = 0.0;
        for (final var transacao : transacoes) {
            final double sinal = transacao.tipo == 'D' ? 1 : -1;
            final double valor = transacao.getValorMoedaLocal();
            saldo += sinal * valor;
        }

        return saldo;
    }

    private double getValorMoedaLocal() {
        final double multiplo = moeda.equals(MOEDA_LOCAL) ? 1 : CurrencyAPI.getQuote(moeda, MOEDA_LOCAL);
        return multiplo * valor;
    }

    public Integer getId() {
        return id;
    }

    public String getCliente() {
        return cliente;
    }

    public double getValor() {
        return valor;
    }

    public String getMoeda() {
        return moeda;
    }

    public char getTipo() {
        return tipo;
    }

    public static List<Transacao> getLista() {
        return Collections.unmodifiableList(lista);
    }

    @Override
    public String toString() {
        return "Transacao [id=" + id + ", cliente=" + cliente + ", valor=" + valor + ", moeda=" + moeda + ", tipo="
                + tipo + "]";
    }
    
}

