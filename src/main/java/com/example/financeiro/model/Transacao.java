package com.example.financeiro.model;

import java.util.*;
import java.util.function.Predicate;
import java.util.stream.Collectors;

public class Transacao {
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

    public List<Transacao> lista = new LinkedList<>();

    public void adicionar(Transacao t) {
        lista.add(t);
    }

    public List<Transacao> filtrar(String cliente){
        return filtrar(transacao -> transacao.getCliente().equals(cliente));
    }
    
    public List<Transacao> filtrar(char tipo){
        return filtrar(transacao -> transacao.getTipo() == tipo);
    }

    public List<Transacao> filtrar(String cliente, char tipo){
        return filtrar(transacao -> transacao.getCliente().equals(cliente) && transacao.getTipo() == tipo);
    }

    private List<Transacao> filtrar(Predicate<Transacao> predicate){
        return lista.stream().filter(predicate).collect(Collectors.toCollection(LinkedList::new));
    }

    public double getSaldo(String cliente) {
        double saldo = 0.0;
        for (Transacao t : lista) {
            if (t.cliente.equals(cliente)) {
                saldo += t.valor;
            }
        }
        return saldo;
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

    public List<Transacao> getLista() {
        return lista;
    }
    

    
}

