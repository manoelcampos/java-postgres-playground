package com.example.financeiro.dao;

import com.example.financeiro.model.Transacao;
import java.time.LocalDateTime;
import java.util.*;
import java.util.function.Predicate;
import java.util.stream.Collectors;

public class TransacaoDAO {
    private final List<Transacao> lista = new LinkedList<>();

    public List<Transacao> getLista() {
        return Collections.unmodifiableList(lista);
    }

    public Transacao adicionar(Transacao nova) {
        if(nova.getTipo() != 'R'){
            lista.add(nova);
            return nova;
        }
            
        int totalRetiradas = 0;
        for (var t : lista) {
            var ontem = nova.getDataHora().minusDays(1);
            if(t.getCliente().equals(nova.getCliente()) && t.getTipo() == 'R' && t.getDataHora().isAfter(ontem)){
                totalRetiradas++;
            } 
        }

        if(totalRetiradas >= 2){
            var copia = Transacao.newSuspeita(nova);
            lista.add(copia);
            return copia;
        } 
        
        lista.add(nova);
        return nova;
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

    public double getSaldo(final String cliente) {
        final var transacoes = filtrar(cliente);

        double saldo = 0.0;
        for (final var transacao : transacoes) {
            final double sinal = transacao.getTipo() == 'D' ? 1 : -1;
            final double valor = transacao.getValorMoedaLocal();
            saldo += sinal * valor;
        }

        return saldo;
    }
    
}
