package com.example.financeiro.model;

import java.time.LocalDateTime;

import com.example.financeiro.currency.CurrencyAPI;

public class Transacao {
    private static final String MOEDA_LOCAL = "BRL";

    private Integer id;
    private String cliente;
    private double valor;
    private String moeda;
    private char tipo;
    private LocalDateTime dataHora;
    private boolean suspeita;
    
    Transacao(String cliente, double valor, String moeda, char tipo, LocalDateTime dataHora) {
        this.cliente = cliente;
        this.valor = valor;
        this.moeda = moeda;
        this.tipo = tipo;
        this.dataHora = dataHora;
    }

    public Transacao(String cliente, double valor, String moeda, char tipo) {
        this(cliente, valor, moeda, tipo, LocalDateTime.now());
    }

    public static Transacao newSuspeita(Transacao t) {
        var copia = new Transacao(t.cliente, t.valor, t.moeda, t.tipo);
        copia.suspeita = true;
        return copia;
    }

    public double getValorMoedaLocal() {
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

    public LocalDateTime getDataHora() {
        return dataHora;
    }

    public boolean isSuspeita() {
        return suspeita;
    }

    @Override
    public String toString() {
        return "Transacao [id=" + id + ", cliente=" + cliente + ", valor=" + valor + ", moeda=" + moeda + ", tipo="
                + tipo + "]";
    }
    
}

